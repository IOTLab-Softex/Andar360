# app/controllers/ocorrencias_controller.rb

class OcorrenciasController < ApplicationController
  before_action :set_ocorrencia, only: [:update, :destroy, :remover_arquivo]

  def create
    @ocorrencia = Ocorrencia.new(ocorrencia_params)
    if @ocorrencia.save
      #processar_anexos(@ocorrencia)
      redirect_to_parent(@ocorrencia.ocorrenciavel, "Ocorrência registrada com sucesso.")
    else
      flash[:alert] = @ocorrencia.errors.full_messages.to_sentence
      redirect_back fallback_location: root_path
    end
  end

def update
  arquivos_novos = params[:ocorrencia].delete(:arquivos)

  if @ocorrencia.update(ocorrencia_params_without_arquivos)
    # Agora anexa adicionalmente os novos arquivos
    if arquivos_novos.present?
      arquivos_novos.reject(&:blank?).each do |arquivo|
        @ocorrencia.arquivos.attach(arquivo)
      end
    end

    redirect_to_parent(@ocorrencia.ocorrenciavel, "Ocorrência atualizada com sucesso.")
  else
    flash[:alert] = @ocorrencia.errors.full_messages.to_sentence
    redirect_to_parent(@ocorrencia.ocorrenciavel, "Erro ao atualizar ocorrência.")
  end
end



  def destroy
    parent = @ocorrencia.ocorrenciavel
    @ocorrencia.destroy
    redirect_to_parent(parent, "Ocorrência excluída com sucesso.")
  end
def remover_arquivo
    # encontra o blob a partir do signed_id
    blob = ActiveStorage::Blob.find_signed(params[:blob_signed_id])
    # encontra o attachment daquela ocorrência
    attachment = @ocorrencia.arquivos_attachments.find_by(blob_id: blob.id)

    if attachment
      attachment.purge_later
      flash[:notice] = "Arquivo da ocorrência removido com sucesso."
    else
      flash[:alert] = "Anexo não encontrado."
    end

    # redireciona de volta ao edit do pai (Chamado ou Manutenção programada)
    parent = @ocorrencia.ocorrenciavel
    redirect_to(
      parent.is_a?(Chamado) ? edit_chamado_path(parent) : edit_manutencao_programada_path(parent),
      notice: flash[:notice], alert: flash[:alert]
    )
  end
  private

  def set_ocorrencia
    @ocorrencia = Ocorrencia.find(params[:id])
  end

  # Strong Parameters ATUALIZADO para a associação polimórfica
  # app/controllers/ocorrencias_controller.rb

 def ocorrencia_params
    params.require(:ocorrencia).permit(
      :ocorrenciavel_type,
      :ocorrenciavel_id,
      :data_ocorrencia,
      :proxima_data,
      :descricao,
      arquivos: [],  # Rails irá anexar esses blobs automaticamente
      checklist_ocorrencias_attributes: [:id, :marcado, :checklist_item_id, :_destroy]
    )
  end
alias_method :ocorrencia_params_without_arquivos, :ocorrencia_params



  # Helper para processar anexos, evitando duplicação de código
  def processar_anexos(ocorrencia)
    return unless ocorrencia.ocorrenciavel.is_a?(ManutencaoProgramada)
    arquivos_params = params[:ocorrencia][:arquivos].reject(&:blank?) rescue []
    return if arquivos_params.empty?

    nome_informado = params[:ocorrencia][:nome].presence
    parent         = ocorrencia.ocorrenciavel

    # pega só os novos blobs que acabaram de ser anexados
    novos_blobs = ocorrencia.arquivos.last(arquivos_params.size)

    existing_blob_ids = parent.arquivo_anexos.map { |a| a.arquivo.blob.id }
    novos_blobs
  .uniq { |b| b.blob.id } # evita repetições mesmo que já venha duplicado no array
  .reject { |b| existing_blob_ids.include?(b.blob.id) }
  .each do |b|
    parent.arquivo_anexos.create!(
      nome: nome_informado || b.filename.to_s,
      arquivo: b.blob
    )
  end

  end

   

  # Helper para redirecionar para o "pai" correto
  def redirect_to_parent(parent, message)
    # Define o tipo de mensagem (notice para sucesso, alert para erro)
    flash_type = message.include?("sucesso") ? :notice : :alert

    path = if parent.is_a?(ManutencaoProgramada)
             edit_manutencao_programada_path(parent)
           elsif parent.is_a?(Chamado)
             edit_chamado_path(parent)
           else
             root_path
           end
    
    redirect_to path, flash_type => message


  end
end