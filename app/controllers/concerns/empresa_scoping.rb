# app/controllers/concerns/empresa_scoping.rb
module EmpresaScoping
    extend ActiveSupport::Concern
  
    def scoped_participants
      if current_user.admin?
        Participant.all
      else
        Participant.where(grupo_empresa_id: current_user.participant&.grupo_empresa_id)
      end
    end
  end
  