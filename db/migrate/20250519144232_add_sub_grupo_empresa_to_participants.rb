class AddSubGrupoEmpresaToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :sub_grupo_empresa, null: true, foreign_key: true
  end
end
