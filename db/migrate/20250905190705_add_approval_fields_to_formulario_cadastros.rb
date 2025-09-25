# db/migrate/20250905190705_add_approval_fields_to_formulario_cadastros.rb
class AddApprovalFieldsToFormularioCadastros < ActiveRecord::Migration[8.0]
  def change
    add_column :formulario_cadastros, :status, :string, null: false, default: "pendente"
    add_column :formulario_cadastros, :aprovado_por_id, :integer
    add_column :formulario_cadastros, :aprovado_em, :datetime
    add_column :formulario_cadastros, :reprovado_por_id, :integer
    add_column :formulario_cadastros, :reprovado_em, :datetime
    add_column :formulario_cadastros, :motivo_reprovacao, :text

    add_index :formulario_cadastros, :status
    add_index :formulario_cadastros, [:cpf, :status]
    add_index :formulario_cadastros, :aprovado_por_id
    add_index :formulario_cadastros, :reprovado_por_id

    add_foreign_key :formulario_cadastros, :users, column: :aprovado_por_id
    add_foreign_key :formulario_cadastros, :users, column: :reprovado_por_id
  end
end
