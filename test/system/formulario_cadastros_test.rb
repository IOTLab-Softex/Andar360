require "application_system_test_case"

class FormularioCadastrosTest < ApplicationSystemTestCase
  setup do
    @formulario_cadastro = formulario_cadastros(:one)
  end

  test "visiting the index" do
    visit formulario_cadastros_url
    assert_selector "h1", text: "Formulario cadastros"
  end

  test "should create formulario cadastro" do
    visit formulario_cadastros_url
    click_on "New formulario cadastro"

    fill_in "Cargo", with: @formulario_cadastro.cargo
    check "Concorda termos" if @formulario_cadastro.concorda_termos
    fill_in "Cpf", with: @formulario_cadastro.cpf
    fill_in "Dias trabalho", with: @formulario_cadastro.dias_trabalho
    fill_in "Email", with: @formulario_cadastro.email
    fill_in "Horario trabalho", with: @formulario_cadastro.horario_trabalho
    fill_in "Nome", with: @formulario_cadastro.nome
    fill_in "Observacao", with: @formulario_cadastro.observacao
    fill_in "Telefone", with: @formulario_cadastro.telefone
    click_on "Create Formulario cadastro"

    assert_text "Formulario cadastro was successfully created"
    click_on "Back"
  end

  test "should update Formulario cadastro" do
    visit formulario_cadastro_url(@formulario_cadastro)
    click_on "Edit this formulario cadastro", match: :first

    fill_in "Cargo", with: @formulario_cadastro.cargo
    check "Concorda termos" if @formulario_cadastro.concorda_termos
    fill_in "Cpf", with: @formulario_cadastro.cpf
    fill_in "Dias trabalho", with: @formulario_cadastro.dias_trabalho
    fill_in "Email", with: @formulario_cadastro.email
    fill_in "Horario trabalho", with: @formulario_cadastro.horario_trabalho
    fill_in "Nome", with: @formulario_cadastro.nome
    fill_in "Observacao", with: @formulario_cadastro.observacao
    fill_in "Telefone", with: @formulario_cadastro.telefone
    click_on "Update Formulario cadastro"

    assert_text "Formulario cadastro was successfully updated"
    click_on "Back"
  end

  test "should destroy Formulario cadastro" do
    visit formulario_cadastro_url(@formulario_cadastro)
    click_on "Destroy this formulario cadastro", match: :first

    assert_text "Formulario cadastro was successfully destroyed"
  end
end
