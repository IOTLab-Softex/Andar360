class AddCtaToAnnouncements < ActiveRecord::Migration[7.1]
  def change
    add_column :announcements, :cta_url,   :string
    add_column :announcements, :cta_label, :string
  end
end
