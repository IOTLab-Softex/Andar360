# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_06_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_logs", force: :cascade do |t|
    t.integer "participant_id", null: false
    t.integer "reservation_id", null: false
    t.datetime "accessed_at", null: false
    t.integer "method"
    t.integer "similarity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_access_logs_on_participant_id"
    t.index ["reservation_id"], name: "index_access_logs_on_reservation_id"
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "arquivo_anexos", force: :cascade do |t|
    t.string "nome"
    t.bigint "manutencao_programada_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "chamado_id"
    t.index ["chamado_id"], name: "index_arquivo_anexos_on_chamado_id"
    t.index ["manutencao_programada_id"], name: "index_arquivo_anexos_on_manutencao_programada_id"
  end

  create_table "chamados", force: :cascade do |t|
    t.string "os"
    t.string "unidade"
    t.string "titulo"
    t.string "prioridade"
    t.string "status"
    t.date "data_resolucao"
    t.boolean "exibir_no_app"
    t.string "local"
    t.string "responsavel"
    t.text "observacao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "room_id"
    t.string "solicitante_nome"
    t.bigint "solicitante_id"
    t.index ["room_id"], name: "index_chamados_on_room_id"
    t.index ["solicitante_id"], name: "index_chamados_on_solicitante_id"
  end

  create_table "checklist_items", force: :cascade do |t|
    t.string "descricao"
    t.bigint "manutencao_programada_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["manutencao_programada_id"], name: "index_checklist_items_on_manutencao_programada_id"
  end

  create_table "checklist_items_ocorrencias", id: false, force: :cascade do |t|
    t.bigint "checklist_item_id", null: false
    t.bigint "ocorrencia_id", null: false
  end

  create_table "checklist_ocorrencia", force: :cascade do |t|
    t.bigint "checklist_item_id", null: false
    t.bigint "ocorrencia_id", null: false
    t.boolean "marcado"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checklist_item_id"], name: "index_checklist_ocorrencia_on_checklist_item_id"
    t.index ["ocorrencia_id"], name: "index_checklist_ocorrencia_on_ocorrencia_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "devices", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.string "ip"
    t.string "user"
    t.string "password"
    t.integer "room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_devices_on_room_id"
  end

  create_table "encomendas", force: :cascade do |t|
    t.string "unidade"
    t.string "codigo"
    t.string "transportadora"
    t.string "tipo"
    t.string "tamanho"
    t.string "remetente"
    t.text "observacao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "destinatario_id"
    t.boolean "entregue", default: false
    t.integer "recebido_por_id"
    t.datetime "entregue_em"
    t.index ["destinatario_id"], name: "index_encomendas_on_destinatario_id"
    t.index ["recebido_por_id"], name: "index_encomendas_on_recebido_por_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "category", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "severity", default: 1, null: false
    t.string "page_path"
    t.text "page_url"
    t.string "page_title"
    t.text "user_agent"
    t.text "selected_text"
    t.text "message"
    t.jsonb "url_params", default: {}
    t.integer "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "release_id"
    t.index ["category"], name: "index_feedbacks_on_category"
    t.index ["page_path"], name: "index_feedbacks_on_page_path"
    t.index ["release_id", "status"], name: "index_feedbacks_on_release_id_and_status"
    t.index ["release_id"], name: "index_feedbacks_on_release_id"
    t.index ["resolved_by_id"], name: "index_feedbacks_on_resolved_by_id"
    t.index ["severity"], name: "index_feedbacks_on_severity"
    t.index ["status"], name: "index_feedbacks_on_status"
    t.index ["url_params"], name: "index_feedbacks_on_url_params", using: :gin
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "formulario_cadastros", force: :cascade do |t|
    t.string "nome"
    t.string "cpf"
    t.string "telefone"
    t.string "email"
    t.string "cargo"
    t.string "horario_trabalho"
    t.string "dias_trabalho"
    t.boolean "concorda_termos"
    t.text "observacao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "grupo_empresa_id"
    t.string "status", default: "pendente", null: false
    t.integer "aprovado_por_id"
    t.datetime "aprovado_em"
    t.integer "reprovado_por_id"
    t.datetime "reprovado_em"
    t.text "motivo_reprovacao"
    t.index ["aprovado_por_id"], name: "index_formulario_cadastros_on_aprovado_por_id"
    t.index ["cpf", "status"], name: "index_formulario_cadastros_on_cpf_and_status"
    t.index ["reprovado_por_id"], name: "index_formulario_cadastros_on_reprovado_por_id"
    t.index ["status"], name: "index_formulario_cadastros_on_status"
  end

  create_table "grupo_empresas", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sala"
    t.string "andar"
    t.string "cnpj"
  end

  create_table "import_logs", force: :cascade do |t|
    t.string "nome"
    t.string "cpf"
    t.string "status"
    t.text "mensagem"
    t.boolean "dados_incompletos"
    t.boolean "sem_foto"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_movimentacoes", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "empresa"
    t.string "responsavel"
    t.text "descricao"
    t.string "tipo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_movimentacoes_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "manutencao_programadas", force: :cascade do |t|
    t.string "titulo"
    t.string "categoria"
    t.string "local"
    t.string "responsavel"
    t.string "periodicidade"
    t.date "data_prevista"
    t.date "data_de_aviso"
    t.integer "dias_para_aviso"
    t.text "observacao"
    t.boolean "exibir_no_app"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meetings_participants", id: false, force: :cascade do |t|
    t.integer "meeting_id", null: false
    t.integer "participant_id", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.string "titulo"
    t.text "corpo"
    t.boolean "lida", default: false
    t.bigint "user_id", null: false
    t.string "notificavel_type"
    t.bigint "notificavel_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["notificavel_type", "notificavel_id"], name: "index_notifications_on_notificavel"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "ocorrencia", force: :cascade do |t|
    t.date "data_ocorrencia"
    t.date "proxima_data"
    t.text "descricao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "checklist_id"
    t.string "ocorrenciavel_type"
    t.bigint "ocorrenciavel_id"
    t.index ["ocorrenciavel_type", "ocorrenciavel_id"], name: "index_ocorrencia_on_ocorrenciavel"
  end

  create_table "participants", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cpf"
    t.string "telefone"
    t.text "photo_base64"
    t.string "hex_id"
    t.integer "grupo_empresa_id"
    t.integer "sub_grupo_empresa_id"
    t.boolean "excluido"
    t.index ["grupo_empresa_id"], name: "index_participants_on_grupo_empresa_id"
    t.index ["sub_grupo_empresa_id"], name: "index_participants_on_sub_grupo_empresa_id"
  end

  create_table "participants_reservations", id: false, force: :cascade do |t|
    t.integer "participant_id", null: false
    t.integer "reservation_id", null: false
  end

  create_table "prestador_servicos", force: :cascade do |t|
    t.string "nome"
    t.string "publicado_no_app"
    t.string "bloqueado"
    t.string "cpf"
    t.string "rg"
    t.string "outro_documento"
    t.string "fone1"
    t.string "fone2"
    t.string "whatsapp"
    t.string "email"
    t.string "site"
    t.string "idoso_ou_pne"
    t.string "tipo_veiculo"
    t.string "placa"
    t.string "fabricante"
    t.string "modelo"
    t.string "cor"
    t.string "nome_fantasia"
    t.string "cnpj"
    t.text "servicos"
    t.text "observacao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "endpoint"
    t.string "p256dh"
    t.string "auth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "releases", force: :cascade do |t|
    t.string "version"
    t.string "stage"
    t.datetime "released_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reservations", force: :cascade do |t|
    t.string "title"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sent_to_facial"
    t.integer "solicitante_id"
    t.integer "responsavel_id"
    t.datetime "finalizada_em"
    t.datetime "solicitantes_enviados_em"
    t.datetime "participantes_enviados_em"
    t.datetime "cancelada_em"
    t.integer "grupo_empresa_id"
    t.datetime "no_show_notificado_em"
    t.datetime "inicio_notificado_em"
    t.datetime "pre_inicio_notificado_em"
    t.index ["grupo_empresa_id"], name: "index_reservations_on_grupo_empresa_id"
    t.index ["room_id"], name: "index_reservations_on_room_id"
  end

  create_table "room_groups", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "room_items", force: :cascade do |t|
    t.bigint "room_id"
    t.string "name", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "modelo"
    t.decimal "valor", precision: 12, scale: 2
    t.index ["name"], name: "index_room_items_on_name"
    t.index ["room_id"], name: "index_room_items_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "floor"
    t.integer "device_id"
    t.string "grupo"
    t.boolean "virtual", default: false
    t.boolean "alugado", default: false
    t.boolean "unidade_vazia", default: false
    t.boolean "ativo", default: true
    t.boolean "espaco_comun", default: false
    t.string "categoria"
    t.string "capacidade"
    t.string "taxa"
    t.decimal "area"
    t.string "matricula"
    t.string "fracao_ideal"
    t.string "fracao_extra"
    t.string "interfone"
    t.string "vagas_garagem"
    t.string "empresa_proprietaria"
    t.string "proprietario_formal"
    t.string "dados_do_inquilino"
    t.bigint "room_group_id"
    t.index ["room_group_id"], name: "index_rooms_on_room_group_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tempo_verificacao_online_unidade"
    t.string "backup_dir"
    t.integer "tempo_verificacao_online"
    t.time "horario_rotina_importacao"
    t.integer "tempo_checagem_acesso"
    t.string "tempo_checagem_acesso_unidade"
    t.integer "tempo_checagem_reservas"
    t.string "tempo_checagem_reservas_unidade"
    t.time "limite_horas_turno_reservas_manha"
    t.time "limite_horas_turno_reservas_tarde"
    t.time "limite_horas_turno_reservas_noite"
    t.string "smtp_from_email"
    t.string "smtp_reply_to"
    t.string "smtp_address"
    t.integer "smtp_port"
    t.string "smtp_domain"
    t.string "smtp_username"
    t.text "smtp_password"
    t.string "smtp_authentication"
    t.boolean "smtp_enable_starttls_auto"
    t.boolean "require_rules_before_reservation", default: false, null: false
    t.string "reservation_rules_title"
    t.boolean "require_room_rules_ack"
    t.string "vapid_public_key"
    t.string "vapid_private_key"
    t.string "vapid_subject"
    t.float "camera_min_ratio"
    t.float "camera_max_ratio"
    t.float "camera_score_threshold"
    t.float "camera_good_score"
    t.float "camera_min_zoom"
    t.float "camera_max_zoom"
    t.float "camera_zoom_width_factor"
    t.float "camera_zoom_height_factor"
    t.integer "camera_blur_strength"
    t.float "camera_blur_saturation"
    t.integer "camera_focus_inner_radius"
    t.integer "camera_focus_outer_radius"
    t.boolean "camera_auto_capture_enabled"
    t.string "camera_mesh_style"
  end

  create_table "solicitacao_compra_items", force: :cascade do |t|
    t.bigint "solicitacao_compra_id", null: false
    t.string "descricao"
    t.integer "quantidade"
    t.decimal "valor_unitario", precision: 10, scale: 2
    t.decimal "total", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["solicitacao_compra_id"], name: "index_solicitacao_compra_items_on_solicitacao_compra_id"
  end

  create_table "solicitacao_compras", force: :cascade do |t|
    t.string "colaborador"
    t.string "setor"
    t.date "item_data"
    t.string "item_descricao"
    t.decimal "valor_estimado", precision: 10, scale: 2
    t.text "justificativa"
    t.integer "forma_pagamento"
    t.integer "parcelas"
    t.string "cidade"
    t.date "data_solicitacao"
    t.string "autorizado_por"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status_autorizacao", default: 0, null: false
    t.text "motivo_rejeicao"
    t.integer "status_compra", default: 0, null: false
    t.text "motivo_cancelamento_compra"
  end

  create_table "solicitacao_participantes", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.string "status", default: "pendente", null: false
    t.text "motivo"
    t.integer "aprovado_por"
    t.datetime "aprovado_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_solicitacao_participantes_on_participant_id"
  end

  create_table "sub_grupo_empresas", force: :cascade do |t|
    t.string "nome"
    t.integer "grupo_empresa_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "can_request_purchase", default: false, null: false
    t.boolean "can_approve_purchase", default: false, null: false
    t.boolean "can_buy", default: false, null: false
    t.boolean "can_view_monitoring", default: false, null: false
    t.index ["grupo_empresa_id"], name: "index_sub_grupo_empresas_on_grupo_empresa_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "role", default: "client"
    t.integer "participant_id"
    t.string "cpf"
    t.boolean "force_password_change"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "blocked", default: false, null: false
    t.index ["blocked"], name: "index_users_on_blocked"
    t.index ["cpf"], name: "index_users_on_cpf", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_sign_in_at"], name: "index_users_on_last_sign_in_at"
    t.index ["participant_id"], name: "index_users_on_participant_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "access_logs", "participants"
  add_foreign_key "access_logs", "reservations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "arquivo_anexos", "chamados"
  add_foreign_key "arquivo_anexos", "manutencao_programadas"
  add_foreign_key "chamados", "participants", column: "solicitante_id"
  add_foreign_key "chamados", "rooms"
  add_foreign_key "checklist_items", "manutencao_programadas"
  add_foreign_key "checklist_ocorrencia", "checklist_items"
  add_foreign_key "checklist_ocorrencia", "ocorrencia", column: "ocorrencia_id"
  add_foreign_key "devices", "rooms"
  add_foreign_key "encomendas", "participants", column: "destinatario_id"
  add_foreign_key "feedbacks", "releases"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "formulario_cadastros", "users", column: "aprovado_por_id"
  add_foreign_key "formulario_cadastros", "users", column: "reprovado_por_id"
  add_foreign_key "item_movimentacoes", "items"
  add_foreign_key "notifications", "users"
  add_foreign_key "participants", "grupo_empresas"
  add_foreign_key "participants", "sub_grupo_empresas"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "reservations", "grupo_empresas"
  add_foreign_key "reservations", "participants", column: "responsavel_id"
  add_foreign_key "reservations", "participants", column: "solicitante_id"
  add_foreign_key "reservations", "rooms"
  add_foreign_key "room_items", "rooms"
  add_foreign_key "rooms", "room_groups"
  add_foreign_key "solicitacao_compra_items", "solicitacao_compras"
  add_foreign_key "solicitacao_participantes", "participants"
  add_foreign_key "sub_grupo_empresas", "grupo_empresas"
  add_foreign_key "users", "participants"
end
