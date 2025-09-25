class SolicitacaoParticipante < ApplicationRecord
  belongs_to :participant
  class SolicitacaoParticipante < ApplicationRecord
  belongs_to :participant
  STATUSES = %w[pendente aprovado rejeitado]

  validates :status, inclusion: { in: STATUSES }
end

end
