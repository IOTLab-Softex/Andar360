# app/models/checklist_item.rb

class ChecklistItem < ApplicationRecord
  # O item pertence a uma manutenção
  belongs_to :manutencao_programada

  # O item tem muitas ligações na tabela de junção
  has_many :checklist_ocorrencias, dependent: :destroy

  # O item tem muitas ocorrências ATRAVÉS das ligações acima
  has_many :ocorrencias, through: :checklist_ocorrencias
  
end