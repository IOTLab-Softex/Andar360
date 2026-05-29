class AddAiAgentSettingsToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :ai_agent_enabled, :boolean, default: false, null: false
    add_column :settings, :ai_agent_api_token, :text
    add_column :settings, :ai_agent_model, :string, default: "gpt-4o-mini"
    add_column :settings, :ai_agent_prompt, :text
  end
end
