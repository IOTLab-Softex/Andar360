require "test_helper"

class FormularioCadastrosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @formulario_cadastro = formulario_cadastros(:one)
  end

  test "should get index" do
    get formulario_cadastros_url
    assert_response :success
  end

  test "should get new" do
    get new_formulario_cadastro_url
    assert_response :success
  end

  test "should create formulario_cadastro" do
    assert_difference("FormularioCadastro.count") do
      post formulario_cadastros_url, params: { formulario_cadastro: { cargo: @formulario_cadastro.cargo, concorda_termos: @formulario_cadastro.concorda_termos, cpf: @formulario_cadastro.cpf, dias_trabalho: @formulario_cadastro.dias_trabalho, email: @formulario_cadastro.email, horario_trabalho: @formulario_cadastro.horario_trabalho, nome: @formulario_cadastro.nome, observacao: @formulario_cadastro.observacao, telefone: @formulario_cadastro.telefone } }
    end

    assert_redirected_to formulario_cadastro_url(FormularioCadastro.last)
  end

  test "should show formulario_cadastro" do
    get formulario_cadastro_url(@formulario_cadastro)
    assert_response :success
  end

  test "should get edit" do
    get edit_formulario_cadastro_url(@formulario_cadastro)
    assert_response :success
  end

  test "should update formulario_cadastro" do
    patch formulario_cadastro_url(@formulario_cadastro), params: { formulario_cadastro: { cargo: @formulario_cadastro.cargo, concorda_termos: @formulario_cadastro.concorda_termos, cpf: @formulario_cadastro.cpf, dias_trabalho: @formulario_cadastro.dias_trabalho, email: @formulario_cadastro.email, horario_trabalho: @formulario_cadastro.horario_trabalho, nome: @formulario_cadastro.nome, observacao: @formulario_cadastro.observacao, telefone: @formulario_cadastro.telefone } }
    assert_redirected_to formulario_cadastro_url(@formulario_cadastro)
  end

  test "should destroy formulario_cadastro" do
    assert_difference("FormularioCadastro.count", -1) do
      delete formulario_cadastro_url(@formulario_cadastro)
    end

    assert_redirected_to formulario_cadastros_url
  end
end
