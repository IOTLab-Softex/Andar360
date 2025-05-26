class AddHexIdToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :hex_id, :string
  end
end
