class RefreshFacialPhotoJob < ApplicationJob
    queue_as :default
  
    def perform(participant_id, reservation_id)
      participant = Participant.find(participant_id)
      reservation = Reservation.find(reservation_id)
      device = reservation.room.device
      return unless device.present? && participant.photo.attached?
  
      photo = MiniMagick::Image.read(participant.photo.download)
      photo_data = Base64.strict_encode64(photo.to_blob)
  
      payload = {
        "FaceList": [
          {
            "UserID": participant.hex_id.to_s,
            "PhotoData": [photo_data]
          }
        ]
      }
  
      update_url = "http://#{device.ip}/cgi-bin/AccessFace.cgi?action=updateMulti"
      headers = { 'Content-Type' => 'application/json' }
      auth = { username: device.user, password: device.password }
  
      File.open(Rails.root.join("log", "face_update_payload_debug.json"), "w") do |file|
        file.write(JSON.pretty_generate(payload))
      end
  
      response = HTTParty.post(
        update_url,
        body: payload.to_json,
        headers: headers,
        digest_auth: auth,
        timeout: 20,
        verify: false
      )
  
      Rails.logger.info "[UpdateFace] #{response.code}: #{response.body}: usuario: #{participant.name}"
    end
  end
  