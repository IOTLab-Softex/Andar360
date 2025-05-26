class SubGrupoEmpresa < ApplicationRecord
  belongs_to :grupo_empresa
  has_many :participants

end
