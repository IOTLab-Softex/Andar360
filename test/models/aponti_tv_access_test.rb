require "test_helper"
require "minitest/mock"

class ApontiTvAccessTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  def with_person(allowed: true, company_id: 70, subgroup_company_id: 70, excluded: false)
    subgroup = Struct.new(:grupo_empresa_id, :can_access_aponti_tv?).new(subgroup_company_id, allowed)
    person = Struct.new(:grupo_empresa, :grupo_empresa_id, :sub_grupo_empresa, :excluido?, :solicitacao_exclusao_pendente, :can_access_aponti_tv?)
      .new(Object.new, company_id, subgroup, excluded, nil, true)
    user = User.new(role: "client", blocked: false)
    user.stub(:participant, person) { yield user, person }
  end

  test "only active users in an authorized subgroup of their own company can enter" do
    with_person { |user, _| assert user.aponti_tv_access? }
    with_person(allowed: false) { |user, _| refute user.aponti_tv_access? }
    with_person(subgroup_company_id: 71) { |user, _| refute user.aponti_tv_access? }
    with_person(excluded: true) { |user, _| refute user.aponti_tv_access? }
    with_person do |user, person|
      user.blocked = true
      refute user.aponti_tv_access?
      user.blocked = false
      person.solicitacao_exclusao_pendente = Object.new
      refute user.aponti_tv_access?
    end
    refute User.new(role: "admin").aponti_tv_access?
  end

  test "clients cannot grant permission or move an existing subgroup to another company" do
    controller = SubGrupoEmpresasController.new
    controller.action_name = "update"
    controller.params = ActionController::Parameters.new(sub_grupo_empresa: {
      nome: "Setor", grupo_empresa_id: 71, can_access_aponti_tv: true
    })
    controller.stub(:current_user, User.new(role: "client")) do
      assert_equal({ "nome" => "Setor" }, controller.send(:sub_grupo_empresa_params).to_h)
    end
    controller.stub(:current_user, User.new(role: "admin")) do
      assert_equal true, controller.send(:sub_grupo_empresa_params)[:can_access_aponti_tv]
    end
  end

  test "individual authorization is required even when the subgroup is enabled" do
    with_person do |user, person|
      person[:can_access_aponti_tv?] = false
      refute user.aponti_tv_access?
      person[:can_access_aponti_tv?] = true
      assert user.aponti_tv_access?
    end
  end

  test "TV access does not require permission to enter Andar360" do
    with_person do |user, person|
      user.can_access_andar360 = false
      assert user.aponti_tv_access?
      refute user.active_for_authentication?
      user.blocked = true
      refute user.aponti_tv_access?
    end
  end

  test "individual authorization is cleared for disabled or mismatched subgroups" do
    participant = Participant.new(grupo_empresa_id: 70, can_access_aponti_tv: true)
    subgroup = SubGrupoEmpresa.new(grupo_empresa_id: 70, can_access_aponti_tv: true)
    participant.stub(:sub_grupo_empresa, subgroup) do
      participant.normalize_aponti_tv_access
      assert participant.can_access_aponti_tv?
      subgroup.grupo_empresa_id = 71
      participant.normalize_aponti_tv_access
      refute participant.can_access_aponti_tv?
      subgroup.grupo_empresa_id = 70
      subgroup.can_access_aponti_tv = false
      participant.can_access_aponti_tv = true
      participant.normalize_aponti_tv_access
      refute participant.can_access_aponti_tv?
    end
  end

  test "only administrators can submit individual authorization" do
    controller = ParticipantsController.new
    controller.params = ActionController::Parameters.new(participant: {name: "Pessoa", can_access_aponti_tv: true})
    controller.stub(:current_user, User.new(role: "operador")) do
      refute controller.send(:participant_params).key?(:can_access_aponti_tv)
    end
    controller.stub(:current_user, User.new(role: "admin")) do
      assert_equal true, controller.send(:participant_params)[:can_access_aponti_tv]
    end
  end
end
