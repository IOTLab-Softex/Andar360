class AddCameraTuningToSettings < ActiveRecord::Migration[8.0]
  def change
    change_table :settings, bulk: true do |t|
      t.float :camera_min_ratio
      t.float :camera_max_ratio
      t.float :camera_score_threshold
      t.float :camera_good_score
      t.float :camera_min_zoom
      t.float :camera_max_zoom
      t.float :camera_zoom_width_factor
      t.float :camera_zoom_height_factor
      t.integer :camera_blur_strength
      t.float :camera_blur_saturation
      t.integer :camera_focus_inner_radius
      t.integer :camera_focus_outer_radius
      t.boolean :camera_auto_capture_enabled
      t.string :camera_mesh_style
    end
  end
end
