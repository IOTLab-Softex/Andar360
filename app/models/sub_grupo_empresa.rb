class SubGrupoEmpresa < ApplicationRecord
  belongs_to :grupo_empresa
  has_many :participants
  
  scope :support_access_enabled, -> { where(can_support_access: true) }
  scope :items_enabled, -> { where(can_manage_items: true) }
  scope :encomendas_enabled, -> { where(can_manage_encomendas: true) }
end
