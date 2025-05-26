class AddGrupoEmpresaToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :grupo_empresa, null: true, foreign_key: true
  end
end
