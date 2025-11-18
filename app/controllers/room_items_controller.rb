# app/controllers/room_items_controller.rb
class RoomItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin_or_operator!
  before_action :set_item, only: [:edit, :update, :destroy]

  def index
    @item       = RoomItem.new
    @room_items = RoomItem.catalog.with_attached_icon
  end

  def new
    @item = RoomItem.new
    if turbo_frame_request?
      render partial: "form", locals: { item: @item }, layout: false
    else
      render :new
    end
  end

def create
  @item = RoomItem.new(item_params.merge(room_id: nil))
  if @item.save
    respond_to do |f|
      f.turbo_stream
      f.html { redirect_to room_items_path, notice: "Item criado." }
    end
  else
    if turbo_frame_request?
      render partial: "form", locals: { item: @item }, status: :unprocessable_entity
    else
      @room_items = RoomItem.catalog.with_attached_icon
      render :index, status: :unprocessable_entity
    end
  end
end

  def edit
    if turbo_frame_request?
      render partial: "form", locals: { item: @item }, layout: false
    else
      render :edit
    end
  end


def update
  if @item.update(item_params)
    respond_to do |f|
      f.html { redirect_to room_items_path, notice: "Item atualizado." }
      f.turbo_stream
    end
  else
    if turbo_frame_request?
      render partial: "form", locals: { item: @item }, status: :unprocessable_entity
    else
      render :edit, status: :unprocessable_entity
    end
  end
end

  def destroy
    @item.destroy
    respond_to do |f|
      f.html { redirect_to room_items_path, notice: "Item excluído." }
      f.turbo_stream
    end
  end
  
  
def bulk_destroy
  ids = params[:ids] || []
  RoomItem.where(id: ids).destroy_all
  redirect_to room_items_path, notice: "#{ids.size} item(ns) excluído(s)."
end
  private

  def set_item
    @item = RoomItem.catalog.find(params[:id])
  end

  def item_params
    params.require(:room_item).permit(:name, :modelo, :valor, :icon)
  end

  def authorize_admin_or_operator!
    unless current_user&.admin? || current_user&.operador?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end
end
