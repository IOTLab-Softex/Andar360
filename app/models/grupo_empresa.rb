class GrupoEmpresa < ApplicationRecord
    has_many :participants
    has_one_attached :logo
    has_many :sub_grupo_empresas, dependent: :destroy
    validates :nome, presence: true
  end
  