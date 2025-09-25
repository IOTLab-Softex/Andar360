# app/controllers/room_groups_controller.rb
class RoomGroupsController < ApplicationController
  before_action :set_room_group, only: [:edit, :update, :destroy]

  def index
    @room_groups = RoomGroup.all
  end

  def new
    @room_group = RoomGroup.new
  end

    def create
    @room_group = RoomGroup.new(room_group_params)
    if @room_group.save
        redirect_to room_groups_path(success_room_group: 1)
    else
        render :index # se estiver na mesma view
    end
    end


  def edit; end

  def update
    if @room_group.update(room_group_params)
      redirect_to room_groups_path, notice: "Grupo atualizado com sucesso."
    else
      render :edit
    end
  end

  def destroy
    @room_group.destroy
    redirect_to room_groups_path, notice: "Grupo removido com sucesso."
  end

  private

  def set_room_group
    @room_group = RoomGroup.find(params[:id])
  end

  def room_group_params
    params.require(:room_group).permit(:name, :description)
  end
end
