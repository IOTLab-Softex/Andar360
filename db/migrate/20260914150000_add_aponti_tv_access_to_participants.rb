class AddApontiTvAccessToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :can_access_aponti_tv, :boolean, default: false, null: false
  end
end
