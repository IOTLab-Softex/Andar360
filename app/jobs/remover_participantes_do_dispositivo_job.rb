class RemoverParticipantesDoDispositivoJob < ApplicationJob
    queue_as :default
  
    def perform(participantes_ids_or_reservation_id = nil, device_id = nil)
      if participantes_ids_or_reservation_id.is_a?(Array) && device_id.present?
        remover_participantes_por_ids(participantes_ids_or_reservation_id, device_id)
      else
        reservation = Reservation.find_by(id: participantes_ids_or_reservation_id)
        if reservation
          Rails.logger.info "[🧩] RemoverParticipantes: Executando para reserva #{reservation.id}"
          remover_participantes_da_reserva(reservation)
        else
          Rails.logger.warn "[❗] RemoverParticipantes: Reserva não encontrada com ID #{participantes_ids_or_reservation_id}"
        end
      end
    end
  
    private
  
    def remover_participantes_da_reserva(reservation)
      device = reservation.room&.device
      unless device.present?
        Rails.logger.warn "[⚠️] Dispositivo não encontrado para a reserva #{reservation.id}"
        return
      end
  
      participantes_ids = [reservation.solicitante_id, reservation.responsavel_id] + reservation.participants.pluck(:id)
      participantes_ids.uniq!
      remover_participantes_por_ids(participantes_ids, device.id)
  
      reservation.update(finalizada_em: Time.current)
      Rails.logger.info "[✅] Participantes removidos e reserva #{reservation.id} marcada como finalizada"
    end
  
    def remover_participantes_por_ids(participantes_ids, device_id)
      device = Device.find_by(id: device_id)
      return unless device.present?
  
      participantes = Participant.where(id: participantes_ids.compact)
      Rails.logger.info "[🔎] Removendo IDs #{participantes.map(&:id)} do dispositivo #{device.ip}"
  
      participantes.each do |participant|
        url = "http://#{device.ip}/cgi-bin/AccessUser.cgi?action=removeMulti&UserIDList[0]=#{participant.hex_id}"
        Rails.logger.info "[🧹] Removendo participante #{participant.name} (hex_id: #{participant.hex_id}) do dispositivo #{device.ip}"
  
        begin
          response = HTTParty.get(
            url,
            digest_auth: { username: device.user, password: device.password },
            headers: { 'Accept' => '*/*' },
            timeout: 20,
            verify: false
          )
          Rails.logger.info "[🔻] Remoção status: #{response.code} - #{response.body}"
        rescue => e
          Rails.logger.error "[💥] Erro ao remover participante #{participant.name}: #{e.message}"
        end
      end
    end
  end