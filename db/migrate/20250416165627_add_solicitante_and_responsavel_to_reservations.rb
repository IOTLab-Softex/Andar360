class AddSolicitanteAndResponsavelToReservations < ActiveRecord::Migration[7.0]
  def change
    add_column :reservations, :solicitante_id, :integer
    add_column :reservations, :responsavel_id, :integer

    add_foreign_key :reservations, :participants, column: :solicitante_id
    add_foreign_key :reservations, :participants, column: :responsavel_id
  end
end
