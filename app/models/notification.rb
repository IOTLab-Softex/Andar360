class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notificavel, polymorphic: true
  

  scope :nao_lidas, -> { where(lida: false) }
  scope :recentes, -> { order(created_at: :desc) }
end
