class AddExcluidoToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :excluido, :boolean
  end
end
