class EnviarParticipantesJob < ApplicationJob
  queue_as :default

  def perform(reservation_id, force: false)
    
    reservation = Reservation.find_by(id: reservation_id)
    return unless reservation
    return if reservation.sent_to_facial && !force

    device = reservation.room&.device
    return unless device.present?

    # Ignora solicitante e responsável
    ids_para_ignorar = [reservation.solicitante_id, reservation.responsavel_id].compact
    participantes = reservation.participants.where.not(id: ids_para_ignorar)

    participantes.each do |participant|
      Rails.logger.info "[📤] Enviando participante extra: #{participant.name} (id #{participant.id})"

      json_data = {
        "UserList": [
          {
            "UserID": participant.hex_id,
            "UserName": participant.name,
            "UserType": 2,
            "UseTime": 20,
            "Authority": 2,
            "Password": participant.cpf.to_s,
            "Doors": [0],
            "TimeSections": [255],
            "ValidFrom": reservation.starts_at.strftime("%Y-%m-%d %H:%M:%S"),
            "ValidTo": reservation.ends_at.strftime("%Y-%m-%d %H:%M:%S")
          }
        ]
      }

      response = HTTParty.post(
        "http://#{device.ip}/cgi-bin/AccessUser.cgi?action=insertMulti",
        body: json_data.to_json,
        headers: { 'Content-Type' => 'application/json' },
        digest_auth: {
          username: device.user,
          password: device.password
        }
      )

      Rails.logger.info "[Facial Sync] Participante #{participant.name}: #{response.code} - #{response.body}"
      UploadFaceToFacialJob.perform_later(participant.id, reservation.id)
    end

    reservation.update(sent_to_facial: true) # marca como enviados
  end
end
