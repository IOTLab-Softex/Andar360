class AddAiAgentVoiceToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :ai_agent_voice, :string, default: "coral"
  end
end
