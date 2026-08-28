# frozen_string_literal: true
class DashboardQuery
  Result = Struct.new(
    :rooms,
    :chamados, :chamados_counts,
    :minhas_reservas,
    :manutencoes, :avisos_manutencao, :avisos_tokens, :ack_ns,
    :encomendas,
    :items,
    :formularios_pendentes,
    :kpis
  )

  def initialize(user)
    @user = user
  end

  def call
  rooms = Room.with_attached_photo.includes(:reservations)

  chamados_scope =
    if admin_ou_operador?
      Chamado.order(created_at: :desc)
    else
      Chamado
        .visiveis_para(@user)
        .order(created_at: :desc)
    end

  # contadores rápidos para os cards
  concluidos_sql  = "LOWER(BTRIM(chamados.status)) IN (?)"
  abertos_sql     = "NOT (LOWER(BTRIM(chamados.status)) IN (?))"
  concluidos_vals = %w[concluído concluido]
  critico_vals    = %w[crítico critico]

  chamados_counts = {
    total_abertos: chamados_scope
      .where("#{abertos_sql}", concluidos_vals)
      .count,

    criticos_abertos: chamados_scope
      .where("#{abertos_sql}", concluidos_vals)
      .where("LOWER(BTRIM(chamados.prioridade)) IN (?)", critico_vals)
      .count,

    concluidos_hoje: chamados_scope
      .where("#{concluidos_sql}", concluidos_vals)
      .where("DATE(chamados.updated_at) = CURRENT_DATE")
      .count
  }

  # ... resto do método continua igual





    manutencoes_scope = if admin_ou_operador?
      ManutencaoProgramada.order(data_prevista: :asc)
    else
      ManutencaoProgramada.where(exibir_no_app: true).order(data_prevista: :asc)
    end

    avisos_manutencao = manutencoes_scope.select(&:dentro_do_periodo_de_aviso?)
    avisos_tokens = avisos_manutencao.map do |m|
      versao = "#{m.updated_at.to_i}-#{m.data_prevista&.strftime('%Y-%m-%d')}"
      "mp:#{m.id}:#{versao}"
    end
    ack_ns = "u#{@user.id}"

    # KPIs extras para os cards
    hoje_inicio = Time.current.beginning_of_day
    hoje_fim    = Time.current.end_of_day

    reservas_hoje = Reservation.where(starts_at: hoje_inicio..hoje_fim).count
    ocupacao_hoje = begin
      total_reservas_cap = rooms.count # (ajuste se quiser outra métrica)
      total_reservas_cap.zero? ? 0 : ((reservas_hoje.to_f / total_reservas_cap) * 100).round
    end

    kpis = {
      reservas_hoje: reservas_hoje,
      ocupacao_hoje: ocupacao_hoje,
      manutencoes_pendentes: manutencoes_scope.where("data_prevista >= ?", Date.current).count
    }

    minhas_reservas = minhas_reservas_scope

    # últimos 7 dias (inclui hoje)
inicio = 6.days.ago.to_date
fim    = Date.current

counts_by_day = Reservation
  .where(starts_at: inicio.beginning_of_day..fim.end_of_day)
  .group("DATE(starts_at)")
  .count # => { "2025-09-30" => 5, ... }

reservas_series = (inicio..fim).map { |d| counts_by_day[d] || 0 }

kpis = {
  reservas_hoje: reservas_hoje,
  ocupacao_hoje: ocupacao_hoje,
  manutencoes_pendentes: manutencoes_scope.where("data_prevista >= ?", Date.current).count,
  reservas_series: reservas_series, # << NOVO
  reservas_series_label: "#{inicio.strftime('%d/%m')}–#{fim.strftime('%d/%m')}" # opcional p/ subtítulo
}

    if @user&.admin?
  usuarios_online = User.online.count
  usuarios_online_por_dia = UserPresence
    .where(presence_on: inicio..fim)
    .group(:presence_on)
    .count
  usuarios_online_series = (inicio..fim).map { |date| usuarios_online_por_dia[date] || 0 }
  feedbacks_pendentes = Feedback.where(resolved_at: nil).count
  feedbacks_total     = Feedback.count
  feedbacks_7d        = Feedback.where("created_at >= ?", 7.days.ago).count

  kpis.merge!(
    usuarios_online:        usuarios_online,
    usuarios_online_series: usuarios_online_series,
    usuarios_online_label:  "#{inicio.strftime('%d/%m')}–#{fim.strftime('%d/%m')}",
    feedbacks_pendentes: feedbacks_pendentes,
    feedbacks_total:     feedbacks_total,
    feedbacks_7d:        feedbacks_7d
  )
end

# --- KPIs: Formulário de Cadastros (admin = todos; client = só da empresa dele) ---
fc_scope =
  if @user&.admin?
    FormularioCadastro.all
  elsif can_view_formularios_card?
    gid = @user.participant&.grupo_empresa_id
    gid.present? ? FormularioCadastro.where(grupo_empresa_id: gid) : FormularioCadastro.none
  else
    FormularioCadastro.none
  end

unless fc_scope.equal?(FormularioCadastro.none)
  fc_pendentes = fc_scope.where(status: 'pendente').count
  fc_total     = fc_scope.count
  fc_7d        = fc_scope.where("created_at >= ?", 7.days.ago).count

  # Série (últimos 7 dias) para sparkline do card (criados no período)
  fc_counts_by_day = fc_scope
    .where(created_at: inicio.beginning_of_day..fim.end_of_day)
    .group("DATE(created_at)")
    .count
  fc_series = (inicio..fim).map { |d| fc_counts_by_day[d] || 0 }

  kpis.merge!(
    fc_pendentes:    fc_pendentes,
    fc_total:        fc_total,
    fc_7d:           fc_7d,
    fc_series:       fc_series,
    fc_series_label: "#{inicio.strftime('%d/%m')}–#{fim.strftime('%d/%m')}"
  )
end


# ... kpis já existentes acima ...

# Encomendas para a empresa do usuário (grupo_empresa)
# Encomendas (empresa do usuário) OU (todas, se admin sem empresa)
formularios_pendentes = fc_scope
  .where(status: "pendente")
  .includes(:grupo_empresa)
  .order(created_at: :desc)
  .limit(8)

gid = @user.participant&.grupo_empresa_id
encomendas_scope = Encomenda.none
items_scope = can_view_items_card? ? Item.order(updated_at: :desc).limit(8) : Item.none

if @user&.admin?
  encomendas_scope = Encomenda.includes(:destinatario).all
  encomendas_pendentes = encomendas_scope.where(entregue: false).count
  encomendas_7d        = encomendas_scope.where("created_at >= ?", 7.days.ago).count

  kpis.merge!(
    encomendas_pendentes: encomendas_pendentes,
    encomendas_7d:        encomendas_7d,
    encomendas_label:     "todas" # label para view
  )

elsif can_view_encomendas_card? && gid.present?
  encomendas_scope = Encomenda
    .includes(:destinatario)
    .joins("INNER JOIN participants ON participants.id = encomendas.destinatario_id")
    .where("participants.grupo_empresa_id = ?", gid)

  encomendas_pendentes = encomendas_scope.where(entregue: false).count
  encomendas_7d        = encomendas_scope.where("encomendas.created_at >= ?", 7.days.ago).count

  kpis.merge!(
    encomendas_pendentes: encomendas_pendentes,
    encomendas_7d:        encomendas_7d,
    encomendas_label:     "empresa" # label para view
  )
end



    Result.new(
      rooms,
      chamados_scope, chamados_counts,
      minhas_reservas,
      manutencoes_scope, avisos_manutencao, avisos_tokens, ack_ns,
      encomendas_scope.order(created_at: :desc).limit(8),
      items_scope,
      formularios_pendentes,
      kpis
    )
  end

  private

  def admin_ou_operador?
    @user&.admin? || @user&.operador?
  end

  def minhas_reservas_scope
    participant_id = @user&.participant_id
    return Reservation.none unless participant_id

    Reservation
      .includes(:room, :solicitante, :responsavel)
      .left_joins(:participants)
      .where(cancelada_em: nil)
      .where("reservations.ends_at > ?", Time.current)
      .where(
        "reservations.solicitante_id = :participant_id OR reservations.responsavel_id = :participant_id OR participants.id = :participant_id",
        participant_id: participant_id
      )
      .distinct
      .order(starts_at: :asc)
      .limit(12)
  end

  def can_view_items_card?
    @user&.admin? || subgrupo_permission_enabled?(:can_manage_items)
  end

  def can_view_encomendas_card?
    @user&.admin? || subgrupo_permission_enabled?(:can_manage_encomendas)
  end

  def can_view_formularios_card?
    @user&.admin? || subgrupo_permission_enabled?(:can_support_access)
  end

  def subgrupo_permission_enabled?(permission)
    participant = @user&.participant
    return false unless participant&.sub_grupo_empresa_id

    SubGrupoEmpresa.where(id: participant.sub_grupo_empresa_id, permission => true).exists?
  end
end
