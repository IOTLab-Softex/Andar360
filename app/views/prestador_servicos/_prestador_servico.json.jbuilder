json.extract! prestador_servico, :id, :nome, :publicado_no_app, :bloqueado, :cpf, :rg, :outro_documento, :fone1, :fone2, :whatsapp, :email, :site, :idoso_ou_pne, :tipo_veiculo, :placa, :fabricante, :modelo, :cor, :nome_fantasia, :cnpj, :servicos, :observacao, :foto, :created_at, :updated_at
json.url prestador_servico_url(prestador_servico, format: :json)
json.foto url_for(prestador_servico.foto)
