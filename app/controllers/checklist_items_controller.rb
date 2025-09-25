class ChecklistItemsController < ApplicationController
  def create
    @item = ChecklistItem.new(checklist_item_params)
    if @item.save
      redirect_to edit_manutencao_programada_path(@item.manutencao_programada)
    else
      render plain: "Erro ao salvar"
    end
  end

  def destroy
    item = ChecklistItem.find(params[:id])
    item.destroy
    redirect_back fallback_location: root_path
  end

  private

  def checklist_item_params
    params.require(:checklist_item).permit(:descricao, :manutencao_programada_id)
  end
end
