class CheckDeviceStatusJob < ApplicationJob
    queue_as :default
  
    def perform
      Rails.logger.info("[CheckDeviceStatusJob] Iniciando verificação de status dos dispositivos...")
  
      Device.find_each do |device|
        next if device.ip.blank?
  
        if device_online?(device.ip)
          device.update(status: 'online')
          Rails.logger.info("[CheckDeviceStatusJob] #{device.name} (#{device.ip}) está ONLINE.")
        else
          device.update(status: 'offline')
          Rails.logger.info("[CheckDeviceStatusJob] #{device.name} (#{device.ip}) está OFFLINE.")
        end
      end
  
      Rails.logger.info("[CheckDeviceStatusJob] Verificação concluída.")
    end
  
    private
  
    def device_online?(ip)
      system("ping -n 1 -w 1000 #{ip} > nul")
    rescue StandardError => e
      Rails.logger.error("[CheckDeviceStatusJob] Erro ao pingar #{ip}: #{e.message}")
      false
    end
  end
  