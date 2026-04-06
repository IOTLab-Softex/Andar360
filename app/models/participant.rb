class Participant < ApplicationRecord
  has_one :user
  has_one :user, dependent: :destroy
  has_many :users, foreign_key: :participant_id
  has_and_belongs_to_many :reservations
  has_one_attached :photo
    has_many :solicitacao_participantes
  belongs_to :sub_grupo_empresa, optional: true

  belongs_to :grupo_empresa, optional: true
  validates :name, :cpf, :telefone, presence: true
  validates :cpf, presence: true, uniqueness: true

  before_save :attach_photo_from_base64
  before_create :generate_hex_id
scope :ativos, -> { where("excluido = ? OR excluido IS NULL", false) }
scope :excluidos, -> { where(excluido: true) }

  scope :by_empresa, ->(user) {
    return all if user.admin?
    where(grupo_empresa_id: user.participant&.grupo_empresa_id)
  }
    def solicitacao_exclusao_pendente
    solicitacao_participantes.where(status: 'pendente').order(created_at: :desc).first
  end
  private

  def generate_hex_id
    # Gera ID hexadecimal curto e exclusivo (4 dígitos hex = 65536 combinações)
    begin
      self.hex_id = SecureRandom.hex(2)
    end while Participant.exists?(hex_id: self.hex_id)
  end

  def attach_photo_from_base64
    return unless photo_base64.present?
  
    content_type = photo_base64[%r{\Adata:(image/(?:png|jpeg|jpg));base64,}i, 1] || "image/jpeg"
    decoded_image = Base64.decode64(photo_base64.sub(%r{\Adata:image/(?:png|jpeg|jpg);base64,}i, ""))
    io = StringIO.new(decoded_image)
  
    # Attach sem trigger automático de análise
    self.photo.attach(
      io: io,
      filename: "photo_#{SecureRandom.hex(4)}.#{content_type.split('/').last}",
      content_type: content_type
    )
  
    # Marca manualmente como "analisado"
    blob = self.photo.blob
    blob.update!(metadata: blob.metadata.merge("analyzed" => true))
  end
  
end
