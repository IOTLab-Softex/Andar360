class User < ApplicationRecord
  belongs_to :participant, optional: true
has_many :notifications, dependent: :destroy

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


end
