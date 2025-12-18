class CreateReleases < ActiveRecord::Migration[8.0]
  def change
    create_table :releases do |t|
      t.string :version
      t.string :stage
      t.datetime :released_at
      t.text :notes

      t.timestamps
    end
  end
end
