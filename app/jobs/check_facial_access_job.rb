require 'httparty'

class CheckFacialAccessJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current
  
    # 🔁 Busca TODAS as reservas ativas (entre início e fim)
    Reservation.where("starts_at <= ? AND ends_at >= ? AND cancelada_em IS NULL AND sent_to_facial IS NOT TRUE",  now, now).find_each do |reservation|

      room = reservation.room
      next if room.nil? || room.device.nil? || room.device.ip.blank?
  
      device = room.device
      puts "[✔] Verificando acessos para reserva ##{reservation.id} (#{reservation.starts_at.strftime("%H:%M:%S")} até #{reservation.ends_at.strftime("%H:%M:%S")}) na sala #{room.name}"
      check_access_logs(reservation, device)
    end
  end
  

  private

  def check_access_logs(reservation, device)
    return if reservation.ends_at <= Time.current
  
    start_time = reservation.starts_at.to_i
    end_time = [reservation.ends_at, Time.current].min.to_i
  
    ip = device.ip.to_s.strip
    return if ip.empty?
  
    username = device.user.to_s.strip
    password = device.password.to_s.strip
    return if username.blank? || password.blank?
  
    url = "http://#{ip}/cgi-bin/recordFinder.cgi?action=find&name=AccessControlCardRec&StartTime=#{start_time}&EndTime=#{end_time}"
    puts "[URL MONTADA] #{url}"
  
    response = HTTParty.get(
      url,
      digest_auth: { username: username, password: password },
      headers: { 'Accept' => '*/*' },
      timeout: 20,
      verify: false
    )
  
    if response.code == 200
      File.open(Rails.root.join("log", "debug_facial_access.log"), "a") do |file|
        file.puts("[#{Time.current}] --- Corpo da resposta da API ---")
        file.puts(response.body)
      end
      
      puts "[✔] Acesso HTTP autorizado"
      lines = response.body.split("\n")
      current = {}
  
      lines.each do |line|
        next unless line.include?("=")
        key_val = line.split("=", 2)
        next unless key_val.length == 2
      
        key = key_val[0].strip
        val = key_val[1].strip
      
        if key.start_with?("records")
          _, field = key.split(".", 2)
          current[field] = val
      
          if field == "UserID"
            puts "[📦] Registro capturado: #{current.inspect}"
            puts "[🔍] Verificando Status=#{current["Status"]} e Method=#{current["Method"]}"
      
            if current["Status"] == "1" && current["Method"] == "15"
              puts "[⚙️] Condições de acesso válidas"
      
              participant = Participant.find_by(hex_id: current["UserID"])
              if participant.nil?
                puts "[⚠️] Participante com hex_id #{current["UserID"]} não encontrado."
              else
                puts "[🧩] Encontrado participante #{participant.name} (id: #{participant.id})"
                
                puts "[📆] Reservation id: #{reservation.id} | accessed_at: #{current["CreateTime"]} => #{Time.at(current["CreateTime"].to_i)}"
                if [reservation.solicitante_id, reservation.responsavel_id].include?(participant.id)
                  Rails.logger.info "[🎯] Solicitante ou responsável identificado. Agendando envio dos demais participantes..."
                  EnviarParticipantesJob.perform_later(reservation.id)
                end
                
                puts "[📄] Dados formatados para o banco:"
                puts JSON.pretty_generate({
                  participant_id: participant.id,
                  reservation_id: reservation.id,
                  accessed_at: Time.at(current["CreateTime"].to_i),
                  method: current["Method"].to_i,
                  similarity: current["Similarity"].to_i
                })
      
                begin
                  AccessLog.create!(
                    participant_id: participant.id,
                    reservation: reservation,
                    accessed_at: Time.at(current["CreateTime"].to_i),
                    method: current["Method"].to_i,
                    similarity: current["Similarity"].to_i
                  )
                  puts "[✅] AccessLog salvo com sucesso"
                rescue => e
                  puts "[💥] Falha ao salvar AccessLog: #{e.class} - #{e.message}"
                end
              end
            else
              puts "[ℹ️] Registro ignorado (Status ou Method inválido)"
            end
      
            current = {}
          end
        end
      end
      
    else
      Rails.logger.error "[✘] Acesso negado (#{response.code}) - #{response.body}"
    end
  rescue => e
    Rails.logger.error "[✘] Erro inesperado ao buscar acessos: #{e.class} - #{e.message}"
  end
  
end
