# app/services/rooms_import_service.rb
require 'roo'
require 'csv'

class RoomsImportService
  HEADERS = [
    "Unidade","Grupo","Proprietário","Cpf/Cnpj","RG","Email (s;)",
    "Fone 1","Fone 2","Publico","Inquilino","Cpf/Cnpj","RG",
    "Email (s;)","Fone 1","Fone 2","Publico","Aluguel","Vazia",
    "Área (m2)","Matrícula do Imóvel","Fração Ideal","Fração Extra",
    "Interfone","Garagem","Cep","Endereço","Número","Bairro",
    "Complemento","Cidade","Proprietário Formal","Cpf/Cnpj",
    "Observação","Virtual","Bloqueado"
  ].freeze

  def self.call(uploaded_io)
    new(uploaded_io).call
  end

  def initialize(uploaded_io)
    @uploaded_io = uploaded_io
    @created = 0
    @updated = 0
    @errors  = []
    # === NOVO: cache e contagem de grupos criados
    @groups_cache = {} # {"bloco a" => room_group_id}
    @groups_created = 0
  end

  def call
    sheet = open_sheet(@uploaded_io)

    header = sheet.row(1).map(&:to_s)
    unless header.include?("Unidade")
      @errors << "Cabeçalho inválido: não encontrei a coluna 'Unidade'."
      return summary
    end

    2.upto(sheet.last_row) do |i|
      row = row_hash(header, sheet.row(i))
      next if row.values.all?(&:blank?)

      begin
        upsert_room!(row)
      rescue => e
        @errors << "Linha #{i}: #{e.message}"
      end
    end

    summary
  end

  private

  def open_sheet(io)
    ext = File.extname(io.original_filename).downcase
    case ext
    when ".xlsx" then Roo::Excelx.new(io.tempfile.path)
    when ".xls"  then Roo::Excel.new(io.tempfile.path)
    when ".csv"  then Roo::CSV.new(io.tempfile.path, csv_options: { col_sep: detect_sep(io) })
    else
      raise "Formato não suportado (use .xls, .xlsx ou .csv)."
    end
  end

  def detect_sep(io)
    content = File.read(io.tempfile.path, encoding: 'bom|utf-8')
    content.include?(";") ? ";" : ","
  end

  def row_hash(header, row_values)
    Hash[header.zip(row_values.map { |v| v.is_a?(String) ? v.strip : v })]
  end

  # === NOVO: normalização simples
  def norm_name(str)
    str.to_s.strip.gsub(/\s+/, ' ')
  end

  # === NOVO: acha ou cria RoomGroup por nome (case/space-insensitive), com cache
  def find_or_create_room_group!(name)
    return nil if name.blank?
    key = name.downcase.strip.gsub(/\s+/, ' ')
    return RoomGroup.find(@groups_cache[key]) if @groups_cache[key]

    rg = RoomGroup.where('LOWER(name) = ?', key).first
    unless rg
      rg = RoomGroup.create!(name: norm_name(name))
      @groups_created += 1
    end
    @groups_cache[key] = rg.id
    rg
  end

  def upsert_room!(r)
    unidade = r["Unidade"].to_s
    raise "Campo 'Unidade' vazio." if unidade.blank?

    room = Room.find_or_initialize_by(name: unidade)

    # ====== GRUPO (NOVO): cria/vincula RoomGroup se vier na planilha
    grupo_nome = norm_name(r["Grupo"])
    if grupo_nome.present?
      rg = find_or_create_room_group!(grupo_nome)
      room.room_group = rg if rg
      # opcional: manter o campo string 'grupo' sincronizado também
      room.grupo = grupo_nome
    end

    # Campos que existem em rooms
    room.empresa_proprietaria = r["Proprietário"].presence
    room.proprietario_formal  = r["Proprietário Formal"].presence
    room.area                 = parse_decimal(r["Área (m2)"])
    room.matricula            = r["Matrícula do Imóvel"].presence
    room.fracao_ideal         = r["Fração Ideal"].presence
    room.fracao_extra         = r["Fração Extra"].presence
    room.interfone            = r["Interfone"].presence
    room.vagas_garagem        = r["Garagem"].presence
    room.virtual              = parse_bool(r["Virtual"])
    room.alugado              = parse_bool(r["Aluguel"])
    room.unidade_vazia        = parse_bool(r["Vazia"])
    # room.ativo = !parse_bool(r["Bloqueado"]) # se desejar inferir

    # Consolidar dados complementares
    room.dados_do_inquilino = build_texto_complementar(r)

    if room.new_record?
      room.save!
      @created += 1
    else
      if room.changed?
        room.save!
        @updated += 1
      end
    end
  end

  def parse_bool(value)
    str = value.to_s.strip.downcase
    return true  if %w[sim s true 1 x yes y].include?(str)
    return false if %w[não nao n false 0].include?(str)
    false
  end

  def parse_decimal(value)
    return nil if value.blank?
    str = value.to_s.tr(".", "").tr(",", ".")
    BigDecimal(str)
  rescue
    nil
  end

  def build_texto_complementar(r)
    partes = []

    prop = []
    prop << "Proprietário: #{r['Proprietário']}".strip if r['Proprietário'].present?
    prop << "CPF/CNPJ: #{r['Cpf/Cnpj']}".strip       if r['Cpf/Cnpj'].present?
    prop << "RG: #{r['RG']}".strip                   if r['RG'].present?
    prop << "E-mails: #{r['Email (s;)']}".strip      if r['Email (s;)'].present?
    prop << "Fones: #{[r['Fone 1'], r['Fone 2']].compact.join(' / ')}".strip if (r['Fone 1'].present? || r['Fone 2'].present?)
    prop << "Público: #{r['Publico']}".strip         if r['Publico'].present?
    partes << "PROPRIETÁRIO\n#{prop.join("\n")}" if prop.any?

    inq = []
    inq << "Inquilino: #{r['Inquilino']}".strip if r['Inquilino'].present?
    inq << "CPF/CNPJ: #{r['Cpf/Cnpj']}".strip   if r['Cpf/Cnpj'].present?
    inq << "RG: #{r['RG']}".strip               if r['RG'].present?
    inq << "E-mails: #{r['Email (s;)']}".strip  if r['Email (s;)'].present?
    inq << "Fones: #{[r['Fone 1'], r['Fone 2']].compact.join(' / ')}".strip if (r['Fone 1'].present? || r['Fone 2'].present?)
    inq << "Público: #{r['Publico']}".strip     if r['Publico'].present?
    partes << "INQUILINO\n#{inq.join("\n")}" if inq.any?

    ender = []
    ender << "CEP: #{r['Cep']}" if r['Cep'].present?
    if r['Endereço'].present?
      linha = [r['Endereço'], r['Número']].compact.join(', ')
      linha = [linha, r['Complemento']].compact.join(' - ')
      ender << linha
    end
    ender << [r['Bairro'], r['Cidade']].compact.join(' - ').strip if (r['Bairro'].present? || r['Cidade'].present?)
    partes << "ENDEREÇO\n#{ender.join("\n")}" if ender.any?

    obs = []
    obs << "Observação: #{r['Observação']}" if r['Observação'].present?
    partes << obs.join("\n") if obs.any?

    partes.join("\n\n").presence
  end

  def summary
    {
      created: @created,
      updated: @updated,
      errors:  @errors,
      # === NOVO: expor quantos grupos foram criados
      groups_created: @groups_created
    }
  end
end
