class ReservationsController < ApplicationController
  before_action :set_reservation, only: %i[show edit update destroy status cancel]
  before_action :prepare_form_data, only: %i[new create edit]

  # GET /reservations
  def index
    if current_user.admin? || current_user.operador?
      @reservations = Reservation.includes(:room, :grupo_empresa).order(starts_at: :desc)
    else
      empresa_id = current_user.participant&.grupo_empresa_id
      @reservations = Reservation.includes(:room, :grupo_empresa)
                                 .where(grupo_empresa_id: empresa_id)
                                 .order(starts_at: :desc)
    end
  end

  # GET /reservations/1
  def show
    @participants = @reservation.participants
  end

  # GET /reservations/new
  def new
    raw_attrs = flash[:reservation_attrs] || params[:reservation]
    raw_attrs = raw_attrs.to_unsafe_h if raw_attrs&.respond_to?(:to_unsafe_h)
    @reservation = Reservation.new(raw_attrs || {})
    # (@participants, @grupo_empresas, @rooms) já vêm de prepare_form_data
  end

  # GET /reservations/1/edit
  def edit
    @participants = scoped_participants
  end

  # POST /reservations
  def create
    @reservation = Reservation.new(reservation_params)

    # 1) Nenhuma sala selecionada
  if @reservation.room_id.blank?
    msg = "⚠️ Selecione uma sala para continuar."
    flash_error("Selecione uma sala para continuar.")
    respond_to do |format|
      format.json { render json: { error: msg }, status: :unprocessable_entity }
      format.html do
        flash[:alert] = msg
        flash[:reservation_attrs] = reservation_params # mantém o que o usuário preencheu
        redirect_to new_reservation_path, status: :see_other
      end
    end
    return
  end

  # 2) Sala não encontrada
  room = Room.find_by(id: @reservation.room_id)
  unless room
    msg = "⚠️ Sala não encontrada."
    respond_to do |format|
      format.json { render json: { error: msg }, status: :unprocessable_entity }
      format.html do
        flash[:alert] = msg
        flash[:reservation_attrs] = reservation_params
        redirect_to new_reservation_path, status: :see_other
      end
    end
    return
  end

  # 3) Sala encontrada mas não é espaço comum
  unless room.espaco_comun?
    msg = "⚠️ Esta sala não está disponível para reserva."
    respond_to do |format|
      format.json { render json: { error: msg }, status: :unprocessable_entity }
      format.html do
        flash[:alert] = msg
        flash[:reservation_attrs] = reservation_params
        redirect_to new_reservation_path, status: :see_other
      end
    end
    return
  end
  
    room = Room.find_by(id: @reservation.room_id)
    unless room&.espaco_comun?
      respond_to do |format|
        msg = "⚠️ Esta sala não está disponível para reserva."
        format.json { render json: { error: msg }, status: :unprocessable_entity }
        format.html do
          flash[:alert] = msg
          redirect_back fallback_location: new_reservation_path
        end
      end
      return
    end

    @reservation.grupo_empresa_id ||= current_user.participant&.grupo_empresa_id

    if conflict_exists?(@reservation)
      respond_to do |format|
        format.json { render json: { error: "Já existe uma reserva nesse horário para essa sala." }, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: new_reservation_path, alert: "⚠️ Já existe uma reserva nesse horário para essa sala." }
      end
      return
    end

    campos = [:title, :starts_at, :ends_at, :room_id, :solicitante_id, :responsavel_id]
    vazios = campos.select { |campo| @reservation.send(campo).blank? }

    if vazios.size == campos.size
      respond_to do |format|
        format.json { render json: { error: "⚠️ Preencha o formulário antes de enviar." }, status: :unprocessable_entity }
        format.html do
          flash[:alert] = "⚠️ Preencha o formulário antes de enviar."
          redirect_back fallback_location: new_reservation_path
        end
      end
      return
    elsif @reservation.starts_at.blank? || @reservation.ends_at.blank?
      respond_to do |format|
        format.json { render json: { error: "⚠️ Preencha os campos de início e término da reserva." }, status: :unprocessable_entity }
        format.html do
          flash[:alert] = "⚠️ Preencha os campos de início e término da reserva."
          redirect_back fallback_location: new_reservation_path
        end
      end
      return
    end

    if @reservation.ends_at <= @reservation.starts_at
      respond_to do |format|
        msg = "⚠️ A data/hora final deve ser maior que a data/hora inicial."
        format.json { render json: { error: msg }, status: :unprocessable_entity }
        format.html do
          flash[:alert] = msg
          redirect_back fallback_location: new_reservation_path
        end
      end
      return
    end

    respond_to do |format|
      duracao = ((@reservation.ends_at - @reservation.starts_at) / 3600.0).round(2)
      turno = turno_da_reserva(@reservation.starts_at)
      settings = Setting.first

      limite_time = case turno
        when :manha then settings&.limite_horas_turno_reservas_manha
        when :tarde then settings&.limite_horas_turno_reservas_tarde
        when :noite then settings&.limite_horas_turno_reservas_noite
        end

      # Converte HH:MM (relógio) para horas de duração (float), seguro contra timezone
      horas_limite = limite_time&.respond_to?(:seconds_since_midnight) ? (limite_time.seconds_since_midnight / 3600.0) : nil

      if horas_limite && duracao > horas_limite
        msg = "A duração (#{duracao.round(2)}h) excede o limite de #{horas_limite.round(2)}h para o turno #{turno}."

        flash[:alert] = "⚠️ #{msg}"
        flash[:reservation_attrs] = reservation_params # guarda os campos preenchidos

        redirect_to new_reservation_path, status: :see_other
        return
      end

      Reservation.transaction do
        Room.lock.find(@reservation.room_id)

        if conflict_exists?(@reservation)
          format.json { render json: { error: "Já existe uma reserva nesse horário para essa sala." }, status: :unprocessable_entity }
          format.html { redirect_back fallback_location: new_reservation_path, alert: "⚠️ Já existe uma reserva nesse horário para essa sala." }
          raise ActiveRecord::Rollback
        end

        if @reservation.save
          format.json {
            render json: {
                     success: true,
                     message: "Reserva criada com sucesso.",
                     redirect_url: room_reservations_path(@reservation.room_id),
                   }, status: :created
          }
          format.html { redirect_to room_reservations_path(@reservation.room_id), notice: "Reserva criada com sucesso." }
           flash_success("Reserva criada com sucesso!")
        else
          format.json { render json: { error: @reservation.errors.full_messages.join(", ") }, status: :unprocessable_entity }
          format.html do
            flash[:alert] = @reservation.errors.full_messages.map { |msg| "⚠️ #{msg}" }.join(" • ")
            redirect_back fallback_location: new_reservation_path
            flash_error(@reservation.errors.full_messages.map { |msg| "⚠️ #{msg}" }.join(" • "))
          end
        end
      end
    end
  end

  def reservations
    room = Room.find(params[:room_id])
    now = Time.current

    icon_map = {
      "Cadeiras" => "chair-office",
      "TV" => "tv",
      "Mesa" => "table",
      "Projetor" => "video",
      "Telefone" => "phone",
      "Lousa" => "chalkboard",
      "Ar Condicionado" => "air-conditioner",
      "HDMI" => "hdmi",
      "Tomadas" => "outlet",
    }

    reservations = room.reservations
      .where(cancelada_em: nil)
      .where("ends_at > ?", now)
      .order(:starts_at)

    render json: {
             reservas: reservations.map { |r|
               {
                 id: r.id,
                 title: r.title,
                 starts_at: r.starts_at.strftime("%d/%m %H:%M"),
                 ends_at: r.ends_at.strftime("%d/%m %H:%M"),
               }
             },
             itens: room.room_items.map { |i|
               icon_name = icon_map[i.name]
               {
                 name: i.name,
                 quantity: i.quantity,
                 icon_svg: icon_name ? view_context.svg_icon("icones/icons_custom/solid/#{icon_name}.svg", class: "srs-solid") : "",

               }
             },
           }
  end

  def turno_da_reserva(hora)
    hora = hora.strftime("%H:%M")

    settings = Setting.first
    manha = settings.limite_horas_turno_reservas_manha.strftime("%H:%M") rescue "12:00"
    tarde = settings.limite_horas_turno_reservas_tarde.strftime("%H:%M") rescue "18:00"

    if hora < manha
      :manha
    elsif hora < tarde
      :tarde
    else
      :noite
    end
  end

  def update
    old_solicitante_id = @reservation.solicitante_id
    old_responsavel_id = @reservation.responsavel_id
    old_participant_ids = @reservation.participant_ids.sort

    incoming_params = reservation_params

    new_solicitante_id = incoming_params[:solicitante_id].to_i
    new_responsavel_id = incoming_params[:responsavel_id].to_i
    new_participant_ids = (incoming_params[:participant_ids] || []).map(&:to_i).sort

    solicitante_changed = old_solicitante_id != new_solicitante_id
    responsavel_changed = old_responsavel_id != new_responsavel_id
    participants_changed = old_participant_ids != new_participant_ids

    # 🚨 BLOQUEIO: não permite trocar solicitante/responsável se já enviados
    if Time.current >= @reservation.starts_at && @reservation.sent_to_facial
      if solicitante_changed || responsavel_changed
        redirect_back fallback_location: edit_reservation_path(@reservation),
                      alert: "⚠️ Não é permitido alterar o solicitante ou responsável após o solicitante ou responsável ter acessado a sala."
        return
      end
    end

    respond_to do |format|
      if @reservation.update(incoming_params)
        if Time.current >= @reservation.starts_at
          if solicitante_changed || responsavel_changed
            Rails.logger.info "[Facial Sync] Solicitante ou responsável alterados → disparando AddParticipantToFacialJob"
            AddParticipantToFacialJob.perform_later(@reservation.id)
          end

          if participants_changed
            Rails.logger.info "[Facial Sync] Participantes alterados → disparando EnviarParticipantesJob"
            EnviarParticipantesJob.perform_later(@reservation.id, force: true)
          end
        end

        format.html { redirect_to @reservation, notice: "Reserva atualizada com sucesso." }
        format.json { render :show, status: :ok, location: @reservation }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reservations/1
  # DELETE /reservations/1
  def destroy
    now = Time.current

    participantes_ids = []

    if @reservation.sent_to_facial
      # Remove todos: solicitante, responsável e participantes
      participantes_ids << @reservation.solicitante_id if @reservation.solicitante_id.present?
      participantes_ids << @reservation.responsavel_id if @reservation.responsavel_id.present?
      participantes_ids += @reservation.participants.pluck(:id)
    else
      # Remove apenas solicitante e responsável se foram enviados
      participantes_ids << @reservation.solicitante_id if @reservation.solicitantes_enviados_em.present?
      participantes_ids << @reservation.responsavel_id if @reservation.solicitantes_enviados_em.present?
    end

    participantes_ids.uniq!

    # Limpar os access_logs manualmente para evitar erro de foreign key
    AccessLog.where(reservation_id: @reservation.id).delete_all

    if @reservation.room&.device.present? && participantes_ids.any?
      RemoverParticipantesDoDispositivoJob.perform_later(participantes_ids, @reservation.room.device.id)
    end

    @reservation.destroy!

    redirect_back fallback_location: reservations_path, status: :see_other, notice: "Reserva excluída com sucesso."
  end

  # DELETE /reservations/:id/cancel
  # DELETE /reservations/:id/cancel
  def cancel
    now = Time.current

    if now < @reservation.starts_at
      # Reserva ainda não iniciou → apenas cancela no banco
      @reservation.update(cancelada_em: now)
      redirect_back fallback_location: reservations_path, notice: "Reserva cancelada (antes do início). Nenhum dado foi enviado ao dispositivo."
      return
    end

    participantes_ids = []

    if @reservation.sent_to_facial
      # Remove todos: solicitante, responsável e participantes
      participantes_ids << @reservation.solicitante_id if @reservation.solicitante_id.present?
      participantes_ids << @reservation.responsavel_id if @reservation.responsavel_id.present?
      participantes_ids += @reservation.participants.pluck(:id)
    else
      # Remove apenas solicitante e responsável se foram enviados
      participantes_ids << @reservation.solicitante_id if @reservation.solicitantes_enviados_em.present?
      participantes_ids << @reservation.responsavel_id if @reservation.solicitantes_enviados_em.present?
    end

    participantes_ids.uniq!
    @reservation.update(cancelada_em: now)

    if @reservation.room&.device.present? && participantes_ids.any?
      RemoverParticipantesDoDispositivoJob.perform_later(participantes_ids, @reservation.room.device.id)
    end

    redirect_back fallback_location: reservations_path, notice: "Reserva cancelada com sucesso."
  end

  # GET /reservations/:id/status
  def status
    render json: { sent_to_facial: @reservation.sent_to_facial || false }
  end

  # GET /rooms/:room_id/reservations
def by_room
  @room = Room.find(params[:room_id])

  # escopo base: todas reservas da sala
  scope = @room.reservations.includes(:grupo_empresa).order(starts_at: :asc)

  # se vier ?date=YYYY-MM-DD, filtra só aquele dia
  if params[:date].present?
    begin
      date = Date.parse(params[:date])
      scope = scope.where(starts_at: date.beginning_of_day..date.end_of_day)
    rescue ArgumentError
      # se a data for inválida, ignora o filtro
    end
  end

  if current_user.admin? || current_user.operador?
    @reservations    = scope
    @outras_reservas = []
  else
    empresa_id = current_user.participant&.grupo_empresa_id

    @reservations    = scope.where(grupo_empresa_id: empresa_id)
    @outras_reservas = scope.where.not(grupo_empresa_id: empresa_id)
  end
end

  private

  def conflict_exists?(reservation, updating: false)
    query = Reservation.where(room_id: reservation.room_id)
                       .where("starts_at < ? AND ends_at > ?", reservation.ends_at, reservation.starts_at)
                       .where(cancelada_em: nil)
                       .where("ends_at > ?", Time.current) # <-- ignora encerradas

    # Se for atualização (update), ignora ele mesmo
    query = query.where.not(id: reservation.id) if updating

    query.exists?
  end

  def set_reservation
    @reservation = Reservation.find(params[:id])
    authorize_empresa!(@reservation)
  end

  def authorize_empresa!(reservation)
    # Admin e operador podem tudo
    return if current_user.admin? || current_user.operador?

    empresa_id_user = current_user.participant&.grupo_empresa_id

    if reservation.grupo_empresa_id != empresa_id_user
      redirect_to reservations_path, alert: "Você não tem permissão para acessar esta reserva."
    end
  end

  def reservation_params
    params.require(:reservation).permit(
      :title, :starts_at, :ends_at, :room_id,
      :solicitante_id, :responsavel_id, :rules_accepted,
      participant_ids: [],
    )
  end

  def prepare_form_data
    if current_user.admin? || current_user.operador?
      @participants = Participant.all
      @grupo_empresas = GrupoEmpresa.all
      @rooms = Room.where(espaco_comun: true)
    else
      empresa_id = current_user.participant&.grupo_empresa_id
      @participants = Participant.where(grupo_empresa_id: empresa_id)
      @grupo_empresas = GrupoEmpresa.where(id: empresa_id)
      @rooms = Room.where(espaco_comun: true)
    end
  end
end
