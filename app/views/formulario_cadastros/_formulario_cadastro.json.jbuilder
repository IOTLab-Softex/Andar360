json.extract! formulario_cadastro, :id, :nome, :cpf, :telefone, :email, :cargo, :horario_trabalho, :dias_trabalho, :foto, :concorda_termos, :observacao, :created_at, :updated_at
json.url formulario_cadastro_url(formulario_cadastro, format: :json)
json.foto url_for(formulario_cadastro.foto)
