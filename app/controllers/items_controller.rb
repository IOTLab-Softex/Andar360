class ItemsController < ApplicationController
  before_action :set_item, only: %i[ show edit update destroy ]
  before_action :authorize_items_portaria!

  def index
    @items = Item.all
@empresas = GrupoEmpresa.includes(:participants)
@participants = Participant.all
@ultima_movimentacao_por_item = ItemMovimentacao
  .where(tipo: "retirada")
  .includes(:item)
  .group_by(&:item_id)
  .transform_values do |movs|
    mov = movs.last
    {
      empresa_id: GrupoEmpresa.find_by(nome: mov.empresa)&.id,
      responsavel_id: Participant.find_by(name: mov.responsavel)&.id
    }
  end




  end

  def show
  end

  def new
    @item = Item.new
  end

  def edit
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      redirect_to items_path, notice: "Item was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @item.update(item_params)
      redirect_to items_path, notice: "Item was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def retirar
  item = Item.find(params[:id])
  item.update(status: "em uso")
  redirect_to dashboard_path, notice: "Item retirado com sucesso."
end

def devolver
  item = Item.find(params[:id])
  item.update(status: "disponivel")
  redirect_to dashboard_path, notice: "Item devolvido com sucesso."
end

def registrar_retirada
  item = Item.find(params[:id])

  movimentacao = item.item_movimentacoes.build(
    empresa: params[:empresa],
    responsavel: Participant.find(params[:responsavel_id]).name,
    descricao: params[:descricao],
    tipo: "retirada"
  )

  if movimentacao.save
    item.update(status: "em uso")
    redirect_to items_path, notice: "Item retirado com sucesso."
  else
    redirect_to items_path, alert: "Erro ao registrar retirada."
  end
end

def registrar_devolucao
  item = Item.find(params[:id])
  item.update(status: "disponivel")

item.item_movimentacoes.create!(
  tipo: "devolucao",
  descricao: params[:descricao],
  responsavel: Participant.find(params[:responsavel_id]).name,
  empresa: GrupoEmpresa.find(params[:grupo_empresa_id]).nome
)


  redirect_to items_path, notice: "Item devolvido com sucesso!"
end

def limpar_historico
  item = Item.find(params[:id])
  item.item_movimentacoes.destroy_all
 redirect_to edit_item_path(item), notice: "Histórico de movimentações limpo com sucesso."

end



  def destroy
    @item.destroy!
    redirect_to items_path, notice: "Item was successfully destroyed.", status: :see_other
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:nome, :descricao, :status, :foto)
  end

  def authorize_items_portaria!
    return if can_manage_items?

    redirect_to root_path, alert: "Acesso não autorizado."
  end
end
