class GrupoEmpresa < ApplicationRecord
    has_many :participants
    has_one_attached :logo
    has_many :sub_grupo_empresas, dependent: :destroy
    has_and_belongs_to_many :announcements,
                            join_table: :announcement_grupo_empresas
    validates :nome, presence: true
      has_many :users, optional: true rescue nil
    def notification_emails
    emails = []
    emails << email if respond_to?(:email) && email.present?
    emails << contato_email if respond_to?(:contato_email) && contato_email.present?
    emails << responsavel_email if respond_to?(:responsavel_email) && responsavel_email.present?
    emails += users.where.not(email: [nil, ""]).pluck(:email) if respond_to?(:users)
    emails.uniq
  end
  end
  