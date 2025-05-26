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

ActiveRecord::Schema[8.0].define(version: 2025_05_23_134503) do
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

  create_table "grupo_empresas", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sala"
    t.string "andar"
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

  create_table "meetings_participants", id: false, force: :cascade do |t|
    t.integer "meeting_id", null: false
    t.integer "participant_id", null: false
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
    t.index ["grupo_empresa_id"], name: "index_participants_on_grupo_empresa_id"
    t.index ["sub_grupo_empresa_id"], name: "index_participants_on_sub_grupo_empresa_id"
  end

  create_table "participants_reservations", id: false, force: :cascade do |t|
    t.integer "participant_id", null: false
    t.integer "reservation_id", null: false
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
    t.index ["grupo_empresa_id"], name: "index_reservations_on_grupo_empresa_id"
    t.index ["room_id"], name: "index_reservations_on_room_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "floor"
    t.integer "device_id"
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
  end

  create_table "sub_grupo_empresas", force: :cascade do |t|
    t.string "nome"
    t.integer "grupo_empresa_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["cpf"], name: "index_users_on_cpf", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["participant_id"], name: "index_users_on_participant_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "access_logs", "participants"
  add_foreign_key "access_logs", "reservations"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "devices", "rooms"
  add_foreign_key "participants", "grupo_empresas"
  add_foreign_key "participants", "sub_grupo_empresas"
  add_foreign_key "reservations", "grupo_empresas"
  add_foreign_key "reservations", "participants", column: "responsavel_id"
  add_foreign_key "reservations", "participants", column: "solicitante_id"
  add_foreign_key "reservations", "rooms"
  add_foreign_key "sub_grupo_empresas", "grupo_empresas"
  add_foreign_key "users", "participants"
end
