require 'httparty'

class OpenDoorJob < ApplicationJob
  queue_as :default

  def perform(device_ip, username, password, channel = 1)
    Rails.logger.info("[OpenDoorJob] Iniciando abertura da porta no dispositivo #{device_ip} (Canal #{channel})")

    url = "http://#{device_ip}/cgi-bin/accessControl.cgi?action=openDoor&channel=#{channel}"

    begin
      response = HTTParty.get(
        url,
        digest_auth: { username: username, password: password }, # <-- só digest_auth aqui
        headers: { 'Accept' => 'application/json' },
        timeout: 20,
        verify: false # Ignorar SSL se precisar
      )

      Rails.logger.info("[OpenDoorJob] Resposta do dispositivo: #{response.code} - #{response.body}")
    rescue HTTParty::Error => e
      Rails.logger.error("[OpenDoorJob] Erro HTTParty: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("[OpenDoorJob] Erro inesperado: #{e.message}")
    end
  end
end
