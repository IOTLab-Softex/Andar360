require "test_helper"

class PasswordRecoveriesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "support recovery finds an active support user from another company" do
    requester_company = GrupoEmpresa.create!(nome: "Empresa solicitante")
    requester = Participant.create!(name: "Solicitante", cpf: "11111111111", telefone: "81999999999", grupo_empresa: requester_company)
    requester_user = User.create!(cpf: requester.cpf, email: "requester@example.test", password: "password", role: "client", participant: requester)
    support_company = GrupoEmpresa.create!(nome: "Empresa de suporte")
    support_group = SubGrupoEmpresa.create!(nome: "Suporte", grupo_empresa: support_company, can_support_access: true)
    support = Participant.create!(name: "Atendimento Global", cpf: "22222222222", telefone: "81888888888", grupo_empresa: support_company, sub_grupo_empresa: support_group)
    User.create!(cpf: support.cpf, email: "support@example.test", password: "password", role: "client", participant: support, blocked: false)

    post support_lookup_password_recovery_path, params: { cpf: requester.cpf }, as: :json
    assert_response :success
    post support_request_password_recovery_path, params: { cpf: requester.cpf }, as: :json

    assert_response :success
    chamado = Chamado.order(:id).last
    assert_equal requester, chamado.solicitante
    assert_equal support.name, chamado.responsavel
    assert chamado.password_recovery_support_request?
    assert_equal requester_user.email, chamado.password_recovery_target_user.email
  end
end
