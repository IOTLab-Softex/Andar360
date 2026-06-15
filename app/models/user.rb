class User < ApplicationRecord
  DEFAULT_NOTIFICATION_PREFERENCES = %w[info success warning system].freeze
  NOTIFICATION_PREFERENCE_KEYS = DEFAULT_NOTIFICATION_PREFERENCES.freeze

  belongs_to :participant, optional: true
has_many :notifications, dependent: :destroy
has_many :push_subscriptions, dependent: :destroy
has_many :announcement_views, dependent: :destroy
has_many :viewed_announcements, through: :announcement_views, source: :announcement

  # ⚠️ Altere aqui para usar CPF como login
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         authentication_keys: [:cpf]

 enum :role, { client: "client", operador: "operador", admin: "admin" }


  validates :cpf, presence: true, uniqueness: true
  validates :role, presence: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  # 🔍 Override para login via CPF
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    cpf = conditions.delete(:cpf)
    where(conditions).where(["cpf = ?", cpf.strip]).first
  end
  # app/models/user.rb
def self.find_for_database_authentication(warden_conditions)
  conditions = warden_conditions.dup
  cpf = conditions.delete(:cpf)&.gsub(/\D/, "") # remove pontuação

  where(conditions).where("REPLACE(REPLACE(REPLACE(cpf, '.', ''), '-', ''), ' ', '') = ?", cpf).first
end

# app/models/user.rb
def blocked_access?
  # ✅ bloqueio manual (só se a coluna existir)
  return true if respond_to?(:blocked?) && blocked?

  p = participant
  return false if p.nil?

  return true if p.excluido?
  p.solicitacao_exclusao_pendente.present?
end



def active_for_authentication?
  super && !blocked_access?
end

def inactive_message
  :inactive
end

def self.reset_password_within
  Setting.instance.password_recovery_reset_within
rescue StandardError
  super
end

def normalized_dashboard_card_order(available_cards)
  allowed = Array(available_cards).map(&:to_s)
  saved = Array(dashboard_card_order).map(&:to_s)
  ordered = saved & allowed

  (allowed - ordered).each do |card_id|
    desired_index = allowed.index(card_id) || ordered.length
    insert_at = ordered.each_index.find { |index| (allowed.index(ordered[index]) || 0) > desired_index }
    insert_at ? ordered.insert(insert_at, card_id) : ordered << card_id
  end

  ordered
end

def normalized_dashboard_hidden_cards(available_cards)
  allowed = Array(available_cards).map(&:to_s)
  Array(dashboard_hidden_cards).map(&:to_s) & allowed
end

def normalized_notification_preferences
  raw_preferences = has_attribute?(:notification_preferences) ? self[:notification_preferences] : DEFAULT_NOTIFICATION_PREFERENCES
  selected = Array(raw_preferences.presence || DEFAULT_NOTIFICATION_PREFERENCES).map(&:to_s)
  selected & NOTIFICATION_PREFERENCE_KEYS
end

def notification_preferences_enabled
  normalized = normalized_notification_preferences
  normalized.presence || DEFAULT_NOTIFICATION_PREFERENCES
end

def receives_notification_category?(category)
  notification_preferences_enabled.include?(category.to_s)
end

def update_notification_preferences!(values)
  return false unless has_attribute?(:notification_preferences)

  normalized = Array(values).map(&:to_s) & NOTIFICATION_PREFERENCE_KEYS
  update!(notification_preferences: normalized)
end


end
