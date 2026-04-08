class SubGrupoEmpresa < ApplicationRecord
  belongs_to :grupo_empresa
  has_many :participants
  
  scope :support_access_enabled, -> { where(can_support_access: true) }
end
