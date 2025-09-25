class CreateChecklistItemsOcorrenciasJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :checklist_items, :ocorrencias do |t|
      # t.index [:checklist_item_id, :ocorrencia_id]
      # t.index [:ocorrencia_id, :checklist_item_id]
    end
  end
end
