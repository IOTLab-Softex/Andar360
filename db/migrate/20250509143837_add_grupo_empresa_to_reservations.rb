class AddGrupoEmpresaToReservations < ActiveRecord::Migration[7.0]
  def change
    add_reference :reservations, :grupo_empresa, foreign_key: true
  end
end
