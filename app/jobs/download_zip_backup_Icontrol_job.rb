require 'zip'

class DownloadZipBackupIcontrolJob < ApplicationJob
  queue_as :default

  def perform
    setting = Setting.first

    # diretório onde o Incontrol salva os ZIPs
    raw_dir = setting&.backup_dir.presence || "C:/Temp"
    base_dir = raw_dir.tr('\\', '/')
    dir = base_dir

    pattern = /^usuarios_fotos_e_csv.*\.zip$/

    unless Dir.exist?(dir)
      Rails.logger.warn "[⚠️] Diretório de backup não existe: #{dir}"
      Rails.cache.write(
        'backup_status',
        { status: 'erro',
          message: "Atualizando banco: diretório #{dir} não existe no servidor!" }
      )
      return
    end

    zip_files = Dir.entries(dir)
                   .select { |f| f.match?(pattern) }
                   .map    { |f| File.join(dir, f) }
                   .select { |f| File.file?(f) }
                   .sort_by { |f| File.mtime(f) }

    if zip_files.empty?
      Rails.logger.warn "[⚠️] Nenhum arquivo ZIP encontrado em #{dir}"
      Rails.cache.write(
        'backup_status',
        { status: 'finalizado',
          message: "Atualizando banco: nenhuma atualização encontrada!" }
      )
      return
    end

    zip_path    = zip_files.last
    # 🔹 AGORA extraímos SEMPRE em C:\Temp\importDados
    extract_dir = File.join("C:/Temp", "importDados")

    Rails.logger.info "[🧩] ZIP mais recente encontrado: #{File.basename(zip_path)}"
    FileUtils.mkdir_p(extract_dir)
    Dir.children(extract_dir).each do |entry|
      FileUtils.rm_rf(File.join(extract_dir, entry))
    end
    Rails.cache.write(
      'backup_status',
      { status: 'executando',
        message: "Atualizando banco: descompactando atualização mais recente ..." }
    )

    begin
      Zip::File.open(zip_path) do |zip_file|
        if zip_file.entries.empty?
          Rails.logger.warn "[⚠️] ZIP está vazio: #{File.basename(zip_path)}"
          Rails.cache.write(
            'backup_status',
            { status: 'erro',
              message: "Atualizando banco: arquivo ZIP vazio!" }
          )
          return
        end

        zip_file.each do |entry|
          next if entry.directory?

          destination = File.join(extract_dir, File.basename(entry.name))

          begin
            entry.extract(destination) { true }
          rescue => e
            Rails.logger.error "[❌] Erro ao extrair #{entry.name}: #{e.message}"
            Rails.cache.write(
              'backup_status',
              { status: 'erro',
                message: "Atualizando banco: Erro ao descompactar #{entry.name} (#{e.message})" }
            )
          end
        end
      end

      Rails.logger.info "[✅] Extração finalizada: #{extract_dir}"
      Rails.cache.write(
        'backup_status',
        { status: 'finalizado',
          message: "Atualizando banco: atualização descompactada com sucesso!" }
      )

      # 🚀 Próximo job
      ImportDadosIcontrolJob.perform_now
    rescue => e
      Rails.logger.error "[❌] Erro ao abrir ZIP #{File.basename(zip_path)}: #{e.message}"
      Rails.cache.write(
        'backup_status',
        { status: 'erro',
          message: "Atualizando banco: Erro ao abrir atualização! #{e.message}" }
      )
    end
  end
end
