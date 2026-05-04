class User < ApplicationRecord
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

  (saved & allowed) + (allowed - saved)
end


end
