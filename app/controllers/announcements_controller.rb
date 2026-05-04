class AnnouncementsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin_or_operador!, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_announcement, only: [:edit, :update, :destroy, :mark_viewed]

  def index
    @announcements = Announcement.active.includes(:created_by, :announcement_views)
  end

  def new
    @announcement = Announcement.new
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

  def edit; end

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
    params.require(:announcement).permit(:title, :body, :image, :active)
  end
end
