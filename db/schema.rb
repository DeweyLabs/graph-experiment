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

ActiveRecord::Schema[8.0].define(version: 2025_07_18_154415) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "document_chunks", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "organization_id", null: false
    t.text "content"
    t.integer "chunk_index"
    t.text "embedding"
    t.string "pinecone_id"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_document_chunks_on_document_id"
    t.index ["organization_id"], name: "index_document_chunks_on_organization_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "organization_id", null: false
    t.string "external_id"
    t.string "title"
    t.text "content"
    t.json "metadata"
    t.string "embedding_status"
    t.integer "chunk_count"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_documents_on_organization_id"
    t.index ["source_id"], name: "index_documents_on_source_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.json "settings"
    t.string "plan"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "question_answers", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "document_id"
    t.text "question"
    t.text "answer"
    t.text "context"
    t.float "confidence_score"
    t.json "metadata"
    t.string "pinecone_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type", default: "document"
    t.index ["document_id"], name: "index_question_answers_on_document_id"
    t.index ["organization_id", "document_id"], name: "index_question_answers_on_org_id_where_no_doc", where: "(document_id IS NULL)"
    t.index ["organization_id"], name: "index_question_answers_on_organization_id"
    t.index ["source_type"], name: "index_question_answers_on_source_type"
  end

  create_table "sources", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name"
    t.string "adapter_type"
    t.json "config"
    t.string "status"
    t.datetime "last_sync_at"
    t.json "sync_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_sources_on_organization_id"
  end

  add_foreign_key "document_chunks", "documents"
  add_foreign_key "document_chunks", "organizations"
  add_foreign_key "documents", "organizations"
  add_foreign_key "documents", "sources"
  add_foreign_key "question_answers", "documents"
  add_foreign_key "question_answers", "organizations"
  add_foreign_key "sources", "organizations"
end
