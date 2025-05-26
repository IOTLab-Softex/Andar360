class AddFinalizadaEmToReservations < ActiveRecord::Migration[8.0]
  def change
    add_column :reservations, :finalizada_em, :datetime
  end
end
