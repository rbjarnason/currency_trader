# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120519021801) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "quote_targets", :force => true do |t|
    t.string   "symbol"
    t.integer  "processing_time_interval"
    t.boolean  "active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_processing_time"
    t.integer  "exchange_id"
    t.boolean  "yahoo_quote_enabled"
    t.datetime "last_yahoo_processing_time"
  end

  create_table "quote_values", :force => true do |t|
    t.integer  "quote_target_id"
    t.datetime "data_time"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "ask"
  end

  create_table "trading_accounts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "trading_operations", :force => true do |t|
    t.integer  "quote_target_id",        :null => false
    t.integer  "trading_account_id",     :null => false
    t.float    "initial_capital_amount", :null => false
    t.float    "current_capital_amount", :null => false
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "trading_signals", :force => true do |t|
    t.integer  "trading_strategy_id", :null => false
    t.float    "signal",              :null => false
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "trading_strategies", :force => true do |t|
    t.integer  "trading_strategy_template_id",                       :null => false
    t.integer  "trading_strategy_set_id",                            :null => false
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.float    "initial_simulation_capital"
    t.float    "current_simulation_capital"
    t.integer  "number_of_evolution_trading_signals", :default => 0
    t.text     "binary_parameters"
    t.text     "float_parameters"
    t.float    "simulated_fitness"
    t.text     "simulated_trading_signals"
    t.datetime "simulated_start_date"
    t.datetime "simulated_end_date"
  end

  create_table "trading_strategy_populations", :force => true do |t|
    t.integer  "quote_target_id"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.boolean  "complete",                                           :default => false
    t.boolean  "active",                                             :default => false
    t.boolean  "in_process",                                         :default => false
    t.integer  "current_generation",                                 :default => 0
    t.integer  "max_generations"
    t.integer  "population_size"
    t.float    "best_fitness"
    t.datetime "last_processing_start_time"
    t.datetime "last_processing_stop_time"
    t.integer  "best_trading_strategy_set_id"
    t.binary   "population_data",              :limit => 2147483647
  end

  create_table "trading_strategy_sets", :force => true do |t|
    t.integer  "trading_strategy_population_id",                    :null => false
    t.integer  "trading_time_frame_id",                             :null => false
    t.text     "parameters"
    t.float    "fitness_score"
    t.datetime "created_at",                                        :null => false
    t.datetime "updated_at",                                        :null => false
    t.boolean  "complete",                       :default => false
    t.boolean  "error_flag",                     :default => false
    t.boolean  "active",                         :default => false
    t.boolean  "in_population_process",          :default => false
    t.boolean  "in_process",                     :default => false
    t.datetime "last_processing_start_time"
    t.datetime "last_processing_stop_time"
    t.datetime "last_work_unit_time"
    t.integer  "processing_time_interval",       :default => 1800
    t.float    "accumulated_fitness"
  end

  create_table "trading_strategy_templates", :force => true do |t|
    t.string   "name",       :null => false
    t.text     "code",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "trading_time_frames", :force => true do |t|
    t.string   "time_frame"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "from_hour"
    t.integer  "to_hour"
  end

end
