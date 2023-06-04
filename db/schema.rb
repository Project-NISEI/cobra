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

ActiveRecord::Schema[7.0].define(version: 2023_06_03_232606) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "deck_cards", force: :cascade do |t|
    t.bigint "deck_id"
    t.string "name"
    t.integer "quantity"
    t.integer "influence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deck_id"], name: "index_deck_cards_on_deck_id"
  end

  create_table "decks", force: :cascade do |t|
    t.bigint "player_id"
    t.string "side"
    t.string "name"
    t.string "identity"
    t.integer "min_deck_size"
    t.integer "max_influence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "nrdb_id"
    t.index ["player_id"], name: "index_decks_on_player_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "side"
    t.string "faction"
    t.string "nrdb_code"
    t.string "autocomplete"
    t.index ["side"], name: "index_identities_on_side"
  end

  create_table "pairings", id: :serial, force: :cascade do |t|
    t.integer "round_id"
    t.integer "player1_id"
    t.integer "player2_id"
    t.integer "table_number"
    t.integer "score1"
    t.integer "score2"
    t.integer "side"
    t.integer "score1_runner"
    t.integer "score1_corp"
    t.integer "score2_corp"
    t.integer "score2_runner"
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.boolean "intentional_draw", default: false, null: false
    t.boolean "two_for_one", default: false, null: false
    t.index ["player1_id"], name: "index_pairings_on_player1_id"
    t.index ["player2_id"], name: "index_pairings_on_player2_id"
    t.index ["round_id"], name: "index_pairings_on_round_id"
  end

  create_table "players", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "tournament_id"
    t.boolean "active", default: true
    t.string "corp_identity"
    t.string "runner_identity"
    t.integer "seed"
    t.boolean "first_round_bye", default: false
    t.integer "previous_id"
    t.integer "manual_seed"
    t.bigint "user_id"
    t.index ["tournament_id"], name: "index_players_on_tournament_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "registrations", id: :serial, force: :cascade do |t|
    t.integer "player_id"
    t.integer "stage_id"
    t.integer "seed"
    t.index ["player_id"], name: "index_registrations_on_player_id"
    t.index ["stage_id"], name: "index_registrations_on_stage_id"
  end

  create_table "round_timer_activations", force: :cascade do |t|
    t.bigint "tournament_id"
    t.bigint "round_id"
    t.datetime "start_time", default: -> { "now()" }, null: false
    t.datetime "stop_time"
    t.index ["round_id"], name: "index_round_timer_activations_on_round_id"
    t.index ["tournament_id"], name: "index_round_timer_activations_on_tournament_id"
  end

  create_table "rounds", id: :serial, force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "number"
    t.boolean "completed", default: false
    t.decimal "weight", default: "1.0"
    t.integer "stage_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.integer "length_minutes", default: 65
    t.index ["stage_id"], name: "index_rounds_on_stage_id"
    t.index ["tournament_id"], name: "index_rounds_on_tournament_id"
  end

  create_table "stages", id: :serial, force: :cascade do |t|
    t.integer "tournament_id"
    t.integer "number", default: 1
    t.integer "format", default: 0, null: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.index ["tournament_id"], name: "index_stages_on_tournament_id"
  end

  create_table "standing_rows", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.integer "player_id"
    t.integer "stage_id"
    t.integer "points"
    t.decimal "sos"
    t.decimal "extended_sos"
    t.integer "corp_points"
    t.integer "runner_points"
    t.index ["player_id"], name: "index_standing_rows_on_player_id"
    t.index ["stage_id"], name: "index_standing_rows_on_stage_id"
  end

  create_table "tournaments", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil
    t.string "abr_code"
    t.integer "stage", default: 0
    t.integer "previous_id"
    t.integer "user_id"
    t.string "slug"
    t.date "date"
    t.boolean "private", default: false
    t.string "stream_url"
    t.boolean "manual_seed"
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.boolean "self_registration"
    t.boolean "nrdb_deck_registration", default: false
    t.index ["user_id"], name: "index_tournaments_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "nrdb_id"
    t.string "nrdb_username"
    t.string "nrdb_access_token"
    t.string "nrdb_refresh_token"
    t.index ["nrdb_id"], name: "index_users_on_nrdb_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "deck_cards", "decks"
  add_foreign_key "decks", "players"
  add_foreign_key "pairings", "players", column: "player1_id"
  add_foreign_key "pairings", "players", column: "player2_id"
  add_foreign_key "pairings", "rounds"
  add_foreign_key "players", "tournaments"
  add_foreign_key "players", "users"
  add_foreign_key "registrations", "players"
  add_foreign_key "registrations", "stages"
  add_foreign_key "round_timer_activations", "rounds"
  add_foreign_key "round_timer_activations", "tournaments"
  add_foreign_key "rounds", "stages"
  add_foreign_key "rounds", "tournaments"
  add_foreign_key "stages", "tournaments"
  add_foreign_key "standing_rows", "players"
  add_foreign_key "standing_rows", "stages"
  add_foreign_key "tournaments", "users"
end
