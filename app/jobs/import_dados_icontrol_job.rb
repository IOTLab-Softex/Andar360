require 'csv'
require 'base64'
require 'mini_magick'

class ImportDadosIcontrolJob < ApplicationJob
  queue_as :default

  def log_import(nome, cpf, status, mensagem, dados_incompletos: false, sem_foto: false)
    ImportLog.create(
      nome: nome,
      cpf: cpf,
      status: status,
      mensagem: mensagem,
      dados_incompletos: dados_incompletos,
      sem_foto: sem_foto
    )
  end

  def resolve_image_path(base_path)
    %w[.png .jpg .jpeg].each do |ext|
      candidate = "#{base_path}#{ext}"
      return candidate if File.exist?(candidate)
    end
    return base_path if File.exist?(base_path)
    nil
  end

  def resize_image_to_base64(path, width, height)
    full_path = resolve_image_path(path)
    raise "Imagem não encontrada com extensão válida: #{path}" unless full_path

    image = MiniMagick::Image.open(full_path)
    image.resize "#{width}x#{height}"
    image.format "png"

    Base64.strict_encode64(image.to_blob)
  end

  def perform
    base_dir   = "C:/Temp"
  import_dir = File.join(base_dir, "importDados")
  csv_path   = File.join(import_dir, "usuarios.csv")
  dir_fotos  = import_dir

  unless File.exist?(csv_path)
    msg = "Arquivo CSV não encontrado em #{csv_path}"
    Rails.logger.error "[❌] #{msg}"
    log_import("Sistema", "-", "erro", msg)
    Rails.cache.write(
      "backup_status",
      { status: "erro", message: "Importando Atualização: CSV não encontrado em #{csv_path}" }
    )
    return
  end

  # Renomeia arquivos blob_* sem extensão dentro do mesmo import_dir
  Dir.glob(File.join(dir_fotos, "blob_*")).each do |path|
    next if File.extname(path).present?

    begin
      sig = File.open(path, 'rb') { |f| f.read(8) }

      if sig.start_with?("\xFF\xD8".b)
        File.rename(path, "#{path}.jpg")
      elsif sig.start_with?("\x89PNG\r\n\x1A\n".b)
        File.rename(path, "#{path}.png")
      else
        Rails.logger.warn "[⚠️] Arquivo desconhecido, não renomeado: #{path}"
      end
    rescue => e
      Rails.logger.error "[❌] Erro ao tentar renomear #{path}: #{e.message}"
    end
  end

    begin
      csv_raw = File.read(csv_path, mode: "rb")

      # Remove BOM manualmente, se existir
      if csv_raw.bytes[0..2] == [0xEF, 0xBB, 0xBF]
        csv_raw = csv_raw.bytes[3..].pack("C*")
      end

      # Força UTF-8 diretamente
      csv_content = csv_raw.force_encoding("UTF-8")
                           .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

      total_rows = CSV.parse(csv_content, headers: true,
                             col_sep: ";", liberal_parsing: true).size

      CSV.parse(csv_content, headers: true, col_sep: ";", liberal_parsing: true).each_with_index do |row, i|
        nome       = row["Nome_Usuario"]&.strip
        email      = row["E_mail"]&.strip
        cpf        = row["CPF"]&.strip
        telefone   = row["Telefone_celular"]&.strip
        estado     = row["Estado"]&.strip
        nome_grupo = row["local_especifico"]&.strip
        foto_rel   = row["Foto"]&.strip

        if cpf.blank? || email.blank? || nome.blank? || foto_rel.blank?
          msg = "Dados incompletos na linha #{i + 2}: Nome: #{nome}, Email: #{email}, CPF: #{cpf}, Foto: #{foto_rel}"
          Rails.logger.warn "[⏭️] #{msg}"
          log_import(
            nome || "Desconhecido",
            cpf  || "Desconhecido",
            "erro",
            msg,
            dados_incompletos: true,
            sem_foto: foto_rel.blank?
          )
          next
        end

        if estado&.downcase == "inativo"
          participante = Participant.find_by(cpf: cpf)
          if participante
            participante.destroy
            msg = "Participante inativo removido: #{nome} (#{cpf})"
            Rails.logger.info "[🗑️] #{msg}"
            log_import(nome, cpf, "removido", msg)
          end
          next
        end

        foto_base = File.join(dir_fotos, File.basename(foto_rel.tr('\\', '/')))
        base64    = nil

        begin
          base64 = resize_image_to_base64(foto_base, 150, 300)
        rescue => e
          msg = "Foto ausente ou inválida para #{nome} — #{e.message}"
          Rails.logger.warn "[⚠️] #{msg}"
          log_import(nome, cpf, "adicionado_sem_foto", msg, sem_foto: true)
        end

        grupo = GrupoEmpresa.find_or_create_by(nome: nome_grupo.presence || "Grupo Padrão")

        participant = Participant.find_or_initialize_by(cpf: cpf)
        participant.assign_attributes(
          name:          nome,
          email:         email,
          telefone:      telefone,
          grupo_empresa: grupo,
          photo_base64:  base64 ? "data:image/png;base64,#{base64}" : nil
        )

        if participant.save
          msg = "Participante salvo com sucesso: #{participant.name} (#{participant.cpf})"
          Rails.logger.info "[✅] #{msg}"
          log_import(nome, cpf, "adicionado", msg, sem_foto: base64.nil?)

          percentual = (((i + 1).to_f / total_rows) * 100).round
          Rails.cache.write(
            'backup_status',
            {
              status:  'executando',
              message: "Importando Atualização... #{percentual}% concluído (#{i + 1} de #{total_rows})"
            }
          )
        else
          msg = "Erro ao salvar participante #{nome}: #{participant.errors.full_messages.join(', ')}"
          Rails.logger.error "[❌] #{msg}"
          log_import(nome, cpf, "erro", msg)
        end
      end
    rescue => e
      Rails.logger.error "[❌] Erro geral no importador: #{e.message}"
      log_import("Sistema", "-", "erro", "Erro geral: #{e.message}")
      Rails.cache.write(
        'backup_status',
        { status: 'erro', message: "Importando Atualização: erro na importação!" }
      )
    else
      Rails.logger.info "[🏁] Importação finalizada com sucesso."
      log_import("Sistema", "-", "finalizado", "Importação concluída com sucesso.")
      Rails.cache.write(
        'backup_status',
        { status: 'finalizado', message: "Importando Atualização: Importação concluída com sucesso!" }
      )
    end
  end
end
