json.extract! encomenda, :id, :unidade, :codigo, :transportadora, :tipo, :tamanho, :remetente, :destinatario, :observacao, :imagem, :created_at, :updated_at
json.url encomenda_url(encomenda, format: :json)
json.imagem url_for(encomenda.imagem)
