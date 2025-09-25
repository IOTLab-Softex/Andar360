# app/models/formulario_cadastro.rb
class FormularioCadastro < ApplicationRecord
  belongs_to :grupo_empresa, class_name: "GrupoEmpresa", foreign_key: :grupo_empresa_id, optional: true
  has_one_attached :foto
  attr_accessor :foto_base64

  enum :status, {
    pendente:  "pendente",
    aprovado:  "aprovado",
    reprovado: "reprovado"
  }

  validates :nome, :cpf, :telefone, :grupo_empresa_id, presence: true

  # ✅ Só valida quando o registro está pendente
  validate :cpf_unico_em_pendentes, if: :pendente?

  # (opcional, mas recomendado) garante default "pendente" ao criar
  after_initialize :set_default_status, if: :new_record?
  def set_default_status
    self.status ||= "pendente"
  end

  private

  def cpf_unico_em_pendentes
    return if cpf.blank?
    if FormularioCadastro.where(cpf: cpf, status: "pendente").where.not(id: id).exists?
      errors.add(:cpf, "já possui um pré-cadastro pendente.")
    end
  end
end
