require 'zip'

class DownloadZipBackupIcontrolJob < ApplicationJob
  queue_as :default

  def perform
    dir = "C:/Temp"
    pattern = /^arquivo_download.*\.zip$/

    # 🕒 Filtra e ordena os arquivos .zip por data de modificação
    zip_files = Dir.entries(dir)
                   .select { |f| f.match?(pattern) }
                   .map { |f| File.join(dir, f) }
                   .select { |f| File.file?(f) }
                   .sort_by { |f| File.mtime(f) }

    if zip_files.empty?
      Rails.logger.warn "[⚠️] Nenhum arquivo ZIP encontrado em #{dir}"
      Rails.cache.write('backup_status', { status: 'finalizado', message: "Atualizando banco: nenhuma atualização encontrada!" })

      return
    end

    zip_path = zip_files.last # ← ZIP mais recente
    extract_dir = File.join(dir, "importDados")

    Rails.logger.info "[🧩] ZIP mais recente encontrado: #{File.basename(zip_path)}"
    FileUtils.mkdir_p(extract_dir)
    Rails.cache.write('backup_status', { status: 'executando', message: "Atualizando banco: descompactando atualização mais recente ..." })

    begin
      Zip::File.open(zip_path) do |zip_file|
        if zip_file.entries.empty?
          Rails.logger.warn "[⚠️] ZIP está vazio: #{File.basename(zip_path)}"
          Rails.cache.write('backup_status', { status: 'erro', message: "Atualizando banco: Erro atualização com erro! | #{e.message}" })

        end

        zip_file.each do |entry|
          destination = File.join(extract_dir, entry.name)

          begin
            entry.extract(destination) { true } # sobrescreve
          rescue => e
            Rails.logger.error "[❌] Erro ao extrair #{entry.name}: #{e.message}"
            Rails.cache.write('backup_status', { status: 'erro', message: "Atualizando banco: Erro não foi possivel descompactando atualização! #{e.message}" })

          end
        end
      end

      Rails.logger.info "[✅] Extração finalizada: #{extract_dir}"
      Rails.cache.write('backup_status', { status: 'finalizado', message: "Atualizando banco: atualização descompactada com sucesso!" })

      # 🚀 Dispara o próximo job de importação
      ImportDadosIcontrolJob.perform_now
    rescue => e
      Rails.logger.error "[❌] Erro ao abrir ZIP #{File.basename(zip_path)}: #{e.message}"
      Rails.cache.write('backup_status', { status: 'erro', message: "Atualizando banco: Erro ao abrir atualização! #{e.message}" })
    end
  end
end
