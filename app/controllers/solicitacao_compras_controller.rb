class SolicitacaoComprasController < ApplicationController
  before_action :authenticate_user!

before_action :set_solicitacao_compra, only: %i[show edit update destroy autorizar confirm_destroy]
  before_action :load_colaboradores,     only: %i[new edit create update]

  before_action :prevent_edit_if_authorized,    only: %i[edit update]
before_action :prevent_destroy_if_authorized, only: %i[destroy confirm_destroy]

  # 🔒 Permissão de ver
  before_action :ensure_can_view,              only: %i[show]
  # 🔒 Permissão de editar/excluir (proprietário ou admin)
before_action :ensure_can_edit_or_destroy,   only: %i[edit update destroy confirm_destroy]

def index
  # base: admin vê tudo, usuário comum vê só as próprias solicitações
   if current_user&.role == "admin" || current_user&.role == "operador"
    scope = SolicitacaoCompra.all
  else
    if current_user&.participant
      nome = current_user.participant.name
      scope = SolicitacaoCompra.where(colaborador: nome)
    else
      scope = SolicitacaoCompra.none
    end
  end

  # Filtro por colaborador (ignora "Todos os colaboradores")
if params[:colaborador].present? && params[:colaborador] != "Todos os colaboradores"
  scope = scope.where(colaborador: params[:colaborador])
end

# Filtro por setor (ignora "Todos os setores")
if params[:setor].present? && params[:setor] != "Todos os setores"
  scope = scope.where(setor: params[:setor])
end


  # Filtro por faixa de datas (aceita dd/mm/aaaa ou aaaa-mm-dd)
# 👉 Guarda nas variáveis de instância para a view
# Filtro por faixa de datas usando COALESCE(data_solicitacao, created_at::date)
@filter_di = parse_date_param(params[:data_inicio])
@filter_df = parse_date_param(params[:data_fim])

if @filter_di
  scope = scope.where("COALESCE(data_solicitacao, created_at::date) >= ?", @filter_di)
end

if @filter_df
  scope = scope.where("COALESCE(data_solicitacao, created_at::date) <= ?", @filter_df)
end




  @solicitacao_compras = scope
    .includes(:itens)          # evita N+1
    .order(created_at: :desc)

  # ==== mesma lógica usada na tabela para calcular o total de UMA solicitação
  calc_total = lambda do |sc|
    # se preencher o valor_estimado no cabeçalho, usa ele
    return sc.valor_estimado if sc.valor_estimado.present?

    sc.itens.to_a.sum do |it|
      if it.total.present?
        it.total
      else
        (it.quantidade || 0) * (it.valor_unitario || 0)
      end
    end
  end

  # ======= DADOS PARA GRÁFICO / KPIs USANDO OS ITENS =======

  # total geral (somando cada solicitação com a mesma lógica da tabela)
  @total_valor_compras = @solicitacao_compras.sum { |sc| calc_total.call(sc) }
  
  @total_solicitacoes   = @solicitacao_compras.size
  @ticket_medio_compras = @total_solicitacoes.zero? ? 0 : (@total_valor_compras / @total_solicitacoes)

  # por mês, também em Ruby, pra usar a mesma base de cálculo
  grouped = @solicitacao_compras.group_by do |sc|
    (sc.data_solicitacao || sc.created_at.to_date).beginning_of_month
  end

  @compras_por_mes = grouped
    .transform_values { |regs| regs.sum { |sc| calc_total.call(sc) } }
    .sort
    .to_h
end









  def show
    @solicitacao_compra = SolicitacaoCompra.includes(:itens).find(params[:id])
  end

  def new
    @solicitacao_compra = SolicitacaoCompra.new(
      cidade:          "Recife",
      data_solicitacao: Date.today
    )
    @solicitacao_compra.itens.build if @solicitacao_compra.itens.empty?

    # 🔹 se o usuário logado puder SOLICITAR compra, já deixa ele pré-selecionado
    if current_user&.participant
      p = current_user.participant
      if p.sub_grupo_empresa&.can_request_purchase?
        @solicitacao_compra.colaborador = p.name          # coluna string
        @solicitacao_compra.setor       = p.sub_grupo_empresa.nome if @solicitacao_compra.respond_to?(:setor)
      end
    end
  end

 def create
  @solicitacao_compra = SolicitacaoCompra.new(solicitacao_compra_params)

  if @solicitacao_compra.save
    notificar_autorizadores(@solicitacao_compra)
    redirect_to @solicitacao_compra, notice: "Solicitação criada com sucesso."
  else
    render :new, status: :unprocessable_entity
  end
end


  def edit
  end

  def update
    if @solicitacao_compra.update(solicitacao_compra_params)
      redirect_to @solicitacao_compra, notice: "Solicitação atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm_destroy
  # Só renderiza a tela de confirmação
end

  def destroy
    @solicitacao_compra.destroy
    redirect_to solicitacao_compras_path, notice: "Solicitação excluída com sucesso."
  end

def autorizar
  unless can_current_user_authorize?(@solicitacao_compra)
    redirect_to @solicitacao_compra, alert: "Você não tem permissão para autorizar esta solicitação."
    return
  end

  nome_autorizador =
    if current_user&.participant
      current_user.participant.name.presence || current_user.name
    else
      current_user.name
    end

  if @solicitacao_compra.update(
      status_autorizacao: :autorizado,
      autorizado_por:     nome_autorizador
    )

    notificar_solicitante_aprovacao(@solicitacao_compra, nome_autorizador)

    redirect_to @solicitacao_compra, notice: "Solicitação autorizada com sucesso."
  else
    redirect_to @solicitacao_compra,
                alert: "Não foi possível atualizar o status da solicitação."
  end
end




private

def notificar_autorizadores(solicitacao)
  # 🔎 Descobre o participant que é o COLABORADOR da solicitação
  solicitante = Participant.find_by(name: solicitacao.colaborador)

  # Se não achar o participant ou ele não tiver empresa, não tem como descobrir autorizadores
  return unless solicitante&.grupo_empresa_id.present?

  empresa_id = solicitante.grupo_empresa_id

  Rails.logger.debug "[SC][notify] Solicitante=#{solicitante.name} empresa_id=#{empresa_id}"

  # ✅ Busca TODOS os participants da MESMA EMPRESA
  #    que tenham permissão de AUTORIZAR compra (can_approve_purchase = true)
  autorizadores_participants = Participant
    .joins(:sub_grupo_empresa)
    .where(
      sub_grupo_empresas: {
        grupo_empresa_id:     empresa_id,
        can_approve_purchase: true
      }
    )

  Rails.logger.debug "[SC][notify] Autorizadores (participants): " +
    autorizadores_participants.map { |p|
      "#{p.name} (subgrupo=#{p.sub_grupo_empresa.nome}, empresa_id=#{p.sub_grupo_empresa.grupo_empresa_id})"
    }.join(", ")

  # 🔁 Converte para usuários (nem todo participant tem user)
  usuarios_autorizadores = autorizadores_participants
    .map(&:user)
    .compact
    .uniq

  Rails.logger.debug "[SC][notify] Autorizadores (users): " +
    usuarios_autorizadores.map { |u| "#{u.id}-#{u.email}" }.join(", ")

  return if usuarios_autorizadores.empty?

  # 🔔 Cria uma notificação para cada usuário autorizador
  usuarios_autorizadores.each do |user|
    Notification.create!(
      user: user,
      titulo: "Solicitação de compra para aprovação",
      corpo:  "Há uma nova solicitação de compra do colaborador #{solicitacao.colaborador} aguardando sua autorização.",
      lida:   false,
      # Só use esta linha se seu model tiver:
      # belongs_to :notificavel, polymorphic: true
      notificavel: solicitacao
    )
  end
end

def notificar_solicitante_aprovacao(solicitacao, nome_autorizador)
  # 🔎 Descobre o participant que é o COLABORADOR da solicitação
  solicitante = Participant.find_by(name: solicitacao.colaborador)
  return unless solicitante&.user # precisa ter user associado

  usuario_solicitante = solicitante.user

  Notification.create!(
    user:  usuario_solicitante,
    titulo: "Sua solicitação de compra foi aprovada",
    corpo:  "A solicitação de compra criada por você foi aprovada por #{nome_autorizador}.",
    lida:   false,
    notificavel: solicitacao # se seu Notification tiver associação polymorphic
  )
end


def admin?
  current_user&.role == "admin" || current_user&.role == "operador"
end

def owns_solicitacao?(solicitacao)
  return false unless current_user&.participant
  solicitacao.colaborador == current_user.participant.name
end

helper_method :admin?, :owns_solicitacao?


def prevent_edit_if_authorized
  return if admin?                     # ✅ Admin pode editar mesmo autorizada
  return unless @solicitacao_compra.autorizado?

  redirect_to @solicitacao_compra,
              alert: "Esta solicitação já foi autorizada e não pode mais ser alterada."
end

def prevent_destroy_if_authorized
  return if admin?                     # ✅ Admin pode excluir mesmo autorizada
  return unless @solicitacao_compra.autorizado?

  redirect_to solicitacao_compras_path,
              alert: "Esta solicitação já foi autorizada e não pode ser excluída."
end



def ensure_can_view
  return if admin?
  return if owns_solicitacao?(@solicitacao_compra)

  redirect_to solicitacao_compras_path,
              alert: "Você não tem permissão para visualizar esta solicitação."
end

def ensure_can_edit_or_destroy
  return if admin?
  return if owns_solicitacao?(@solicitacao_compra)

  redirect_to solicitacao_compras_path,
              alert: "Você só pode alterar ou excluir as suas próprias solicitações."
end



def can_current_user_authorize?(_solicitacao)
  return false unless current_user

  # 🔒 Obrigatoriamente precisa ser um participant com sub_grupo e permissão
  participant = current_user.participant
  return false unless participant

  sub = participant.sub_grupo_empresa
  return false unless sub

  # ✅ Só quem tem "can_approve_purchase" marcado no sub_grupo_empresa
  sub.can_approve_purchase?
end

helper_method :can_current_user_authorize?



def parse_date_param(str)
  return nil if str.blank?

  # tenta dd/mm/aaaa primeiro
  Date.strptime(str, "%d/%m/%Y")
rescue ArgumentError
  begin
    # tenta formato ISO (aaaa-mm-dd) do date_field_tag
    Date.parse(str)
  rescue ArgumentError
    nil
  end
end


  def set_solicitacao_compra
    @solicitacao_compra = SolicitacaoCompra.find(params[:id])
  end

def solicitacao_compra_params
  params.require(:solicitacao_compra).permit(
    :colaborador,
    :setor,
    :item_data,
    :item_descricao,      # 🔹 usa na tabela
    :valor_estimado,      # 🔹 TOTAL estimado do cabeçalho
    :justificativa,
    :forma_pagamento,
    :parcelas,
    :cidade,
    :data_solicitacao,
    :autorizado_por,

    # 🔹 novos campos:
    :status_autorizacao,
    :motivo_rejeicao,
    :status_compra,

    itens_attributes: [
      :id,
      :descricao,
      :quantidade,
      :valor_unitario,
      :total,
      :_destroy
    ]
  )
end



def load_colaboradores
  # base: todos os participantes com sub_grupo
  participants_scope = Participant.joins(:sub_grupo_empresa)

  # se não for admin NEM operador, filtra pela EMPRESA do usuário logado
  if !admin? && current_user&.participant&.grupo_empresa_id.present?
    empresa_id = current_user.participant.grupo_empresa_id

    participants_scope = participants_scope.where(
      sub_grupo_empresas: { grupo_empresa_id: empresa_id }
    )
  end

  # 🔹 quem pode SOLICITAR compra  -> usa APENAS can_request_purchase
  @colaboradores = participants_scope
                     .where(sub_grupo_empresas: { can_request_purchase: true })
                     .order(:name)

  # 🔹 quem pode AUTORIZAR compra  -> usa APENAS can_approve_purchase
  @autorizadores = participants_scope
                     .where(sub_grupo_empresas: { can_approve_purchase: true })
                     .order(:name)

  Rails.logger.debug "[SC] colaboradores (can_request): " +
                     @colaboradores.map { |p|
                       "#{p.name} (#{p.sub_grupo_empresa.nome} rq=#{p.sub_grupo_empresa.can_request_purchase} ap=#{p.sub_grupo_empresa.can_approve_purchase})"
                     }.join(", ")
end



end