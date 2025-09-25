class Encomenda < ApplicationRecord
  has_one_attached :imagem
   belongs_to :destinatario, class_name: "Participant", optional: true
    belongs_to :recebido_por, class_name: "Participant", optional: true
   belongs_to :sala, optional: true

    scope :entregues, -> { where(entregue: true) }
  scope :nao_entregues, -> { where(entregue: false) }
  validates :unidade, :codigo, :transportadora, presence: true
   

  attr_accessor :notificar_destinatario

  after_create :criar_notificacao_destinatario, if: -> { notificar_destinatario == "1" }

  private

 def criar_notificacao_destinatario
  return unless destinatario&.id

  user = User.find_by(participant_id: destinatario.id)
  return unless user

  Notification.create!(
    user: user,
    titulo: "Chegou encomenda na recepção!",
    corpo: "Você recebeu uma nova encomenda com o código #{codigo}, Compareça a recepção.",
    notificavel: self,
    lida: false
  )
end

end
