class CreateChecklistOcorrencia < ActiveRecord::Migration[8.0]
  def change
    create_table :checklist_ocorrencia do |t|
      t.references :checklist_item, null: false, foreign_key: true
      t.references :ocorrencia, null: false, foreign_key: true
      t.boolean :marcado

      t.timestamps
    end
  end
end
