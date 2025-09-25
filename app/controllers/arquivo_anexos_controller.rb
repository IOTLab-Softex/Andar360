class ArquivoAnexosController < ApplicationController
  def destroy
    manutencao = ManutencaoProgramada.find(params[:manutencao_programada_id])
    anexo = manutencao.arquivo_anexos.find(params[:id])
    anexo.destroy

    redirect_to edit_manutencao_programada_path(manutencao), notice: "Anexo removido com sucesso."
  end
end
