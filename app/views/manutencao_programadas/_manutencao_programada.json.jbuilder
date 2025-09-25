json.extract! manutencao_programada, :id, :titulo, :categoria, :local, :responsavel, :periodicidade, :data_prevista, :dias_para_aviso, :observacao, :exibir_no_app, :created_at, :updated_at
json.url manutencao_programada_url(manutencao_programada, format: :json)
