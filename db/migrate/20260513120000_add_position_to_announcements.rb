class AddPositionToAnnouncements < ActiveRecord::Migration[7.0]
  def up
    add_column :announcements, :position, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        # Initialize positions preserving current created_at desc order
        Announcement.order(created_at: :desc).each_with_index do |ann, i|
          ann.update_column(:position, i)
        end
      end
    end
  end

  def down
    remove_column :announcements, :position
  end
end
