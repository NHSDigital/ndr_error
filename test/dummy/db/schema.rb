# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150918163720) do

  create_table "error_fingerprints", primary_key: "error_fingerprintid", id: :string, force: :cascade do |t|
    t.string   "ticket_url"
    t.string   "status"
    t.integer  "count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["error_fingerprintid"], name: "sqlite_autoindex_error_fingerprints_1", unique: true
  end

  create_table "error_logs", primary_key: "error_logid", id: :string, force: :cascade do |t|
    t.string   "error_fingerprintid"
    t.string   "error_class"
    t.text     "description"
    t.string   "user_roles"
    t.text     "lines"
    t.text     "parameters_yml"
    t.string   "url"
    t.string   "user_agent"
    t.string   "ip"
    t.string   "hostname"
    t.string   "database"
    t.float    "clock_drift"
    t.string   "svn_revision"
    t.integer  "port"
    t.integer  "process_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "custom_user_column"
    t.index ["error_fingerprintid"], name: "index_error_logs_on_error_fingerprintid"
    t.index ["error_logid"], name: "sqlite_autoindex_error_logs_1", unique: true
  end

end
