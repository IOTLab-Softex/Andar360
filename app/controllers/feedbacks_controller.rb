# app/controllers/feedbacks_controller.rb
class FeedbacksController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_feedback, only: [:show, :update, :destroy, :change_status, :assign_to_me, :resolve]
  before_action :ensure_admin!, only: [:index, :show, :update, :destroy, :change_status, :assign_to_me, :resolve]

  # Lista para admins
  def index
    @feedbacks = Feedback.order(created_at: :desc).includes(:user, attachments_attachments: :blob)
    @feedbacks = @feedbacks.where(status: params[:status]) if params[:status].present?
    @feedbacks = @feedbacks.where(category: params[:category]) if params[:category].present?
  end

  # Detalhe (admin)
  def show; end

  # Meus feedbacks (qualquer usuário logado)
  def mine
    @feedbacks = Feedback.where(user_id: current_user.id).order(created_at: :desc)
  end

  # Criação (pode ser anônimo; se tiver usuário logado, associa)
 def create
  @feedback = Feedback.new(feedback_params)
  @feedback.user = current_user if user_signed_in?
  @feedback.user_agent ||= request.user_agent

  # 👉 Associar automaticamente à release atual
  @feedback.release = Release.current

  if @feedback.save
    notificar_admins!(@feedback)
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, notice: "Feedback enviado! Valeu pela ajuda 🙌" }
      format.turbo_stream
      format.json { render json: { ok: true, id: @feedback.id } }
    end
  else
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: @feedback.errors.full_messages.to_sentence }
      format.turbo_stream
      format.json { render json: { ok: false, errors: @feedback.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end


  # Update geral (admin)
  def update
    if @feedback.update(feedback_params)
      redirect_to @feedback, notice: "Feedback atualizado."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @feedback.destroy
    redirect_to feedbacks_path, notice: "Feedback removido."
  end

  # Ações rápidas (admin)
  def change_status
    @feedback.update(status: params[:status]) # ex.: "em_andamento"
    redirect_back fallback_location: feedbacks_path, notice: "Status atualizado para #{@feedback.status.humanize}.", status: :see_other
  end

  def assign_to_me
    @feedback.update(resolved_by: current_user) # usando o mesmo campo como "responsável"
    redirect_back fallback_location: feedbacks_path, notice: "Atribuído a você."
  end

  def resolve
    if @feedback.update(status: :resolvido, resolved_by: current_user, resolved_at: Time.current)
      redirect_back fallback_location: feedbacks_path, notice: "Marcado como resolvido.", status: :see_other
    else
      redirect_back fallback_location: feedbacks_path, alert: @feedback.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def ensure_admin!
    unless user_signed_in? && current_user.role == "admin"
      redirect_to root_path, alert: "Acesso restrito."
    end
  end

  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  def feedback_params
    params.require(:feedback).permit(
      :category, :status, :severity,
      :page_path, :page_url, :page_title, :user_agent,
      :selected_text, :message,
      url_params: {},
      attachments: []
    )
  end

  # opcional: integra com sua tabela notifications
  def notificar_admins!(feedback)
    return unless defined?(Notification) && defined?(User)
    admins = User.where(role: "admin")
    admins.find_each do |admin|
      Notification.create!(
        user: admin,
        titulo: "Novo feedback: #{feedback.category.humanize}",
        corpo: "#{feedback.message.to_s.truncate(140)}\nPágina: #{feedback.page_path}",
        notificavel: feedback
      )
    end
  rescue => e
    Rails.logger.warn("[FeedbacksController] Falha ao notificar admins: #{e.message}")
  end
end
