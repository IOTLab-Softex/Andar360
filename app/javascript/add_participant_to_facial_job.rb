class AddParticipantToFacialJob < ApplicationJob
  queue_as :default

  def perform(participant_id, reservation_id)
     Rails.logger.info "[Facial Sync] Iniciando job para participante #{participant_id}, reserva #{reservation_id}"
    participant = Participant.find(participant_id)
    reservation = Reservation.find(reservation_id)

    device = reservation.room.device

    return unless device.present?

    url = "http://#{device.ip}/cgi-bin/AccessUser.cgi?action=insertMulti"

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
      url,
      body: json_data.to_json,
      headers: { 'Content-Type' => 'application/json' },
      digest_auth: {
        username: device.user,
        password: device.password
      }
    )

    Rails.logger.info "[Facial Sync] #{response.code}: #{response.body}"
    UploadFaceToFacialJob.perform_later(participant_id, reservation_id)
  end
end
