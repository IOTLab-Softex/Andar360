class AddCanceladaEmToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :cancelada_em, :datetime
  end
end
