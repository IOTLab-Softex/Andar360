class ChecklistOcorrencia < ApplicationRecord

  belongs_to :checklist_item
  belongs_to :ocorrencia
   belongs_to :checklist_item
  belongs_to :ocorrencia
end
