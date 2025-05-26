class User < ApplicationRecord
  belongs_to :participant, optional: true

  # ⚠️ Altere aqui para usar CPF como login
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         authentication_keys: [:cpf]

  enum :role, { client: "client", admin: "admin" }

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

end
