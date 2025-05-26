class RenameMeetingsToReservations < ActiveRecord::Migration[6.1]
  def change
    rename_table :meetings, :reservations
  end
end
