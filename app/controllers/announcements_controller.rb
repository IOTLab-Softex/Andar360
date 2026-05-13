class AnnouncementsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin_or_operador!, only: [:new, :create, :edit, :update, :destroy, :reorder]
  before_action :set_announcement, only: [:edit, :update, :destroy, :mark_viewed]

  def index
    Announcement.expire_passed!
    @announcements = Announcement.includes(:created_by, :announcement_views, :grupo_empresas)
                                 .order(position: :asc, created_at: :asc)
  end

  def reorder
    ids = params[:ids] || []
    ids.each_with_index do |id, idx|
      Announcement.where(id: id).update_all(position: idx)
    end
    head :ok
  end

  def new
    @announcement = Announcement.new
    @grupo_empresas = GrupoEmpresa.order(:nome)
    if (gid = current_user.participant&.grupo_empresa_id)
      @announcement.grupo_empresa_ids = [gid]
    end
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.created_by = current_user

    if @announcement.save
      redirect_to announcements_path, notice: "Anúncio criado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @grupo_empresas = GrupoEmpresa.order(:nome)
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to announcements_path, notice: "Anúncio atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    redirect_to announcements_path, notice: "Anúncio removido."
  end

  def mark_viewed
    AnnouncementView.find_or_create_by(user: current_user, announcement: @announcement)
    head :ok
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end

  def authorize_admin_or_operador!
    unless current_user&.admin? || current_user&.operador?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  def announcement_params
    params.require(:announcement).permit(:title, :body, :image, :video, :active, :show_on_login,
                                         :starts_at, :ends_at, :cta_url, :cta_label,
                                         grupo_empresa_ids: [])
  end
end
