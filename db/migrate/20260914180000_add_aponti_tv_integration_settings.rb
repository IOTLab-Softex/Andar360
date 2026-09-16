class AddApontiTvIntegrationSettings < ActiveRecord::Migration[7.0]
  def change
    add_column :settings, :aponti_tv_integration_enabled, :boolean, default: true, null: false
    add_column :settings, :aponti_tv_base_url, :string, default: "http://localhost:3000"
    add_column :settings, :aponti_tv_integration_token, :string
  end
end
