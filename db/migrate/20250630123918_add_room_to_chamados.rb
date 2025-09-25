class AddRoomToChamados < ActiveRecord::Migration[8.0]
  def change
add_reference :chamados, :room, null: true, foreign_key: true

  end
end
