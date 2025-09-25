class SolicitacaoParticipantesController < ApplicationController
def approve
  @solicitacao = SolicitacaoParticipante.find(params[:id])
  @solicitacao.update!(
    status: :aprovado,
    aprovado_por: current_user.id,
    aprovado_em: Time.current
  )
  @solicitacao.participant.update!(excluido: true)
  redirect_to solicitacao_participantes_path, notice: 'Solicitação aprovada e participante marcado como excluído.'
end

def reject
  @solicitacao = SolicitacaoParticipante.find(params[:id])
  @solicitacao.update!(status: :rejeitado)
  redirect_to solicitacao_participantes_path, notice: 'Solicitação rejeitada.'
end

end
