class AddParticipantToFacialJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    Rails.logger.info "[Facial Sync] Iniciando job para reserva #{reservation_id}"

    reservation = Reservation.find(reservation_id)
    device = reservation.room&.device
    return unless device.present?

    participantes = [reservation.solicitante_id, reservation.responsavel_id].compact.map do |pid|
      Participant.find_by(id: pid)
    end.compact

    participantes.each do |participant|
      Rails.logger.info "[Facial Sync] Enviando participante #{participant.id} (#{participant.name})"

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

      Rails.logger.info "[Facial Sync] #{response.code}: #{response.body}"
      UploadFaceToFacialJob.perform_later(participant.id, reservation.id)
    end
  end
end
