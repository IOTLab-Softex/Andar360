json.extract! item, :id, :nome, :descricao, :status, :created_at, :updated_at
json.url item_url(item, format: :json)
