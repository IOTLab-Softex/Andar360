# app/models/ocorrencia.rb

class Ocorrencia < ApplicationRecord

  # A Ocorrência agora pertence a um "ocorrenciavel", que pode ser
  # tanto ManutencaoProgramada quanto Chamado.
  belongs_to :ocorrenciavel, polymorphic: true

  # As associações com arquivos e checklist permanecem.
  has_many_attached :arquivos
  has_many :checklist_ocorrencias, dependent: :destroy
  has_many :checklist_items, through: :checklist_ocorrencias

  # Permite criar registros da tabela de junção diretamente.
  accepts_nested_attributes_for :checklist_ocorrencias
end