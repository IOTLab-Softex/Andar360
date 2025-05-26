require "mini_magick"

class UploadFaceToFacialJob < ApplicationJob
  queue_as :default

  def perform(participant_id, reservation_id)
    participant = Participant.find(participant_id)
    reservation = Reservation.find(reservation_id)
    device = reservation.room.device
    return unless device.present? && participant.photo.attached?

    photo = MiniMagick::Image.read(participant.photo.download)
    photo_data = Base64.strict_encode64(photo.to_blob)

    payload = {
      "UserID": participant.hex_id.to_s,
      "Info": {
        "UserName": "User_#{participant.id}",
        "PhotoData": [photo_data]
      }
    }

    add_url = "http://#{device.ip}/cgi-bin/FaceInfoManager.cgi?action=add"
    headers = { 'Content-Type' => 'application/json' }
    auth = { username: device.user, password: device.password }

    # Debug
    File.open(Rails.root.join("log", "face_payload_debug.json"), "w") do |file|
      file.write(JSON.pretty_generate(payload))
    end

    response = HTTParty.post(
      add_url,
      body: payload.to_json,
      headers: headers,
      digest_auth: auth
    )

    if response.code == 400 && response.body.include?("faceInfoManagerErrorPhotoExist.")
      Rails.logger.info "[Adicionando Face] Já existe. Chamando UpdateFaceJob..."
      UpdateFaceToFacialJob.perform_later(participant.id, reservation.id)
    else
      Rails.logger.info "[Adicionando Face] #{response.code}: #{response.body}: usuario: #{participant.name}"
       Rails.logger.info "[UploadFace] Já existe. Atualizando foto"
      RefreshFacialPhotoJob.perform_later(participant.id, reservation.id)
      
    end
  end
end
