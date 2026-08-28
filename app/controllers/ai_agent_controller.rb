class AiAgentController < ApplicationController
  before_action :authenticate_user!
  include HTTParty

  def chat
    result = AiAgentService.new(
      user: current_user,
      message: params[:message],
      history: session[:ai_agent_history],
      quick_mode: ActiveModel::Type::Boolean.new.cast(params[:quick_mode])
    ).call

    session[:ai_agent_history] = [
      *Array(session[:ai_agent_history]).last(10),
      { "role" => "user", "content" => params[:message].to_s },
      {
        "role" => "assistant",
        "content" => result[:message].to_s,
        "cancelable_reservations" => result[:cancelable_reservations] || result[:reservations],
        "cancelable_maintenances" => result[:cancelable_maintenances] || result[:maintenances]
      }.compact
    ].last(12)

    status = result[:ok] ? :ok : :unprocessable_entity

    render json: result, status: status
  end

  def speech
    setting = Setting.instance
    text = params[:text].to_s.strip

    return render json: { error: "Texto vazio." }, status: :unprocessable_entity if text.blank?
    return render json: { error: "Configure o token do Agente IA." }, status: :unprocessable_entity if setting.ai_agent_api_token.blank?

    response = self.class.post(
      "https://api.openai.com/v1/audio/speech",
      headers: {
        "Authorization" => "Bearer #{setting.ai_agent_api_token}",
        "Content-Type" => "application/json"
      },
      body: {
        model: "gpt-4o-mini-tts",
        voice: speech_voice(setting),
        input: text.first(1800),
        instructions: "Fale em português brasileiro, com tom natural, claro e prestativo.",
        response_format: "mp3"
      }.to_json,
      timeout: 45
    )

    unless response.success?
      message = JSON.parse(response.body).dig("error", "message") rescue "Falha ao gerar audio."
      return render json: { error: message }, status: :unprocessable_entity
    end

    send_data response.body, type: "audio/mpeg", disposition: "inline"
  rescue => e
    render json: { error: "Falha ao gerar audio: #{e.class} - #{e.message}" }, status: :unprocessable_entity
  end

  private

  def speech_voice(setting)
    voice = params[:voice].to_s
    return voice if Setting::AI_AGENT_VOICES.include?(voice)

    setting.ai_agent_voice_or_default
  end
end
