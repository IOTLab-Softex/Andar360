class ParticipantAccessManager
  def self.call(participant, params)
    andar360 = params[:criar_usuario] == "1"
    tv = participant.can_access_aponti_tv? && participant.aponti_tv_eligible?
    user = participant.user
    unless andar360 || tv
      user&.update!(can_access_andar360: false)
      return
    end

    user ||= participant.build_user
    user.cpf = participant.cpf
    user.email = participant.email
    user.can_access_andar360 = andar360
    user.role = andar360 ? (params[:user_role].presence || user.role || "client") : "client"
    if user.new_record? || params[:manter_senha] != "1"
      user.password = params[:senha_gerada].presence || SecureRandom.hex(8)
      user.password_confirmation = user.password
      user.force_password_change = true
    end
    user.save!
  end
end
