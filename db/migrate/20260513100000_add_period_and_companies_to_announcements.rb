class AddPeriodAndCompaniesToAnnouncements < ActiveRecord::Migration[7.1]
  def change
    add_column :announcements, :starts_at, :datetime
    add_column :announcements, :ends_at, :datetime

    create_table :announcement_grupo_empresas, id: false do |t|
      t.bigint :announcement_id, null: false
      t.bigint :grupo_empresa_id, null: false
    end

    add_index :announcement_grupo_empresas, [:announcement_id, :grupo_empresa_id],
              unique: true, name: "idx_ann_grupo_empresas_unique"
    add_index :announcement_grupo_empresas, :grupo_empresa_id,
              name: "idx_ann_grupo_empresa_id"
  end
end
