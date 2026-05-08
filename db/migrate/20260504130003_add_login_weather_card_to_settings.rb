class AddLoginWeatherCardToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :login_weather_card_enabled, :boolean, default: false, null: false
    add_column :settings, :login_weather_city, :string, default: "Recife"
    add_column :settings, :login_weather_latitude, :decimal, precision: 10, scale: 6, default: -8.047562
    add_column :settings, :login_weather_longitude, :decimal, precision: 10, scale: 6, default: -34.877003
  end
end
