class ArquivoAnexo < ApplicationRecord
  belongs_to :manutencao_programada, optional: true
   belongs_to :chamado,               optional: true
  has_one_attached :arquivo
end
