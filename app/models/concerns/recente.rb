# app/models/concerns/recente.rb
module Recente
  extend ActiveSupport::Concern

  def atualizada_recentemente?
    updated_at.present? && updated_at > 24.hours.ago
  end
end
