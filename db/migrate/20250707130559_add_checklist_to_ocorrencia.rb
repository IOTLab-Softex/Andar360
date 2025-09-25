class AddChecklistToOcorrencia < ActiveRecord::Migration[8.0]
  def change
    add_column :ocorrencia, :checklist_id, :integer
  end
end
