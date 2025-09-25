# app/controllers/arquivos_anexos_chamado_controller.rb

class ArquivosAnexosChamadoController < ApplicationController
  # É uma boa prática garantir que o usuário esteja logado para realizar esta ação.
  before_action :authenticate_user!

  def destroy
    # 1. Encontrar o 'pai' (o Chamado) através do ID na URL.
    # O parâmetro é :chamado_id por causa do aninhamento `resources :chamados do ...` nas rotas.
    chamado = Chamado.find(params[:chamado_id])

    # 2. Encontrar o anexo específico que pertence a esse chamado.
    # A associação é 'arquivos_anexos_chamado' como visto no seu ChamadosController.
    # O parâmetro :id refere-se ao próprio anexo que será excluído.
    anexo = chamado.arquivos_anexos_chamado.find(params[:id])

    # 3. Remover o anexo do banco de dados e seus arquivos associados.
    anexo.destroy

    # 4. Redirecionar de volta para a página de edição do chamado com uma mensagem de sucesso.
    # Usamos o `chamado` que encontramos no primeiro passo.
    redirect_to edit_chamado_path(chamado), notice: "Anexo removido com sucesso."
  end
end