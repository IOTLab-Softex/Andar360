class RoomsController < ApplicationController
        before_action :authenticate_user!
before_action :authorize_admin!, except: [:open_door]
before_action :authorize_admin_or_operator!, only: [:open_door]
before_action :set_room, only: %i[show edit update destroy open_door]

  # GET /rooms or /rooms.json
  def index
    @rooms = Room.with_attached_photo
  end

  # GET /rooms/1 or /rooms/1.json
  def show
  end

  # GET /rooms/new
 def new
  @room = Room.new
  @room.room_items.build
end


  # GET /rooms/1/edit
  def edit
  end

  # POST /rooms or /rooms.json
  def create
    @room = Room.new(room_params)

    respond_to do |format|
      if @room.save
        format.html { redirect_to dashboard_path, notice: "Room was successfully created." }
        format.json { render :show, status: :created, location: @room }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  def open_door
    room = Room.find(params[:id])
    device = room.device # Supondo que cada Room tem um Device associado
    if device.present?
      OpenDoorJob.perform_later(device.ip, device.user, device.password)
      flash[:notice] = "Comando para abrir a porta enviado!"
    else
      flash[:alert] = "Dispositivo não encontrado para essa sala."
    end
    redirect_to dashboard_path
  end

  # PATCH/PUT /rooms/1 or /rooms/1.json
  def update
    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to dashboard_path, notice: "Room was successfully updated." }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rooms/1 or /rooms/1.json
  def destroy
    @room.destroy!

    respond_to do |format|
      format.html { redirect_to dashboard_path, status: :see_other, alert: "Room was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  def authorize_admin_or_operator!
  unless current_user&.admin? || current_user&.operador?
    redirect_to root_path, alert: "Acesso não autorizado."
  end
end


    # Use callbacks to share common setup or constraints between actions.
    def set_room
       @room = Room.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def room_params
  params.require(:room).permit(
    :name, :floor, :device_id, :photo,
    room_items_attributes: [:id, :name, :quantity, :_destroy]
  )
end

    
    
    
end
