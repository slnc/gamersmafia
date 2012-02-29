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

ActiveRecord::Schema.define(:version => 20120225180115) do

  create_table "ab_tests", :id => false, :force => true do |t|
    t.integer  "id",                                                                                              :null => false
    t.string   "name",                           :limit => nil,                                                   :null => false
    t.integer  "treatments",                                                                                      :null => false
    t.boolean  "finished",                                                                     :default => false, :null => false
    t.decimal  "minimum_difference",                            :precision => 10, :scale => 2
    t.string   "metrics",                        :limit => nil
    t.string   "info_url",                       :limit => nil
    t.datetime "created_on",                                                                                      :null => false
    t.datetime "completed_on"
    t.decimal  "min_difference",                                :precision => 10, :scale => 2, :default => 0.05,  :null => false
    t.string   "cache_conversion_rates",         :limit => nil
    t.datetime "updated_on",                                                                                      :null => false
    t.boolean  "dirty",                                                                        :default => true,  :null => false
    t.datetime "cache_expected_completion_date"
    t.boolean  "active",                                                                       :default => true,  :null => false
  end

  add_index "ab_tests", ["name"], :name => "ab_tests_name_key", :unique => true

  create_table "ads", :force => true do |t|
    t.datetime "created_on",                   :null => false
    t.datetime "updated_on",                   :null => false
    t.string   "name",          :limit => nil, :null => false
    t.string   "file",          :limit => nil
    t.string   "link_file",     :limit => nil
    t.string   "html",          :limit => nil
    t.integer  "advertiser_id"
  end

  add_index "ads", ["name"], :name => "ads_name_key", :unique => true

  create_table "ads_slots", :force => true do |t|
    t.string  "name",             :limit => nil,                :null => false
    t.string  "location",         :limit => nil,                :null => false
    t.string  "behaviour_class",  :limit => nil,                :null => false
    t.integer "position",                        :default => 0, :null => false
    t.integer "advertiser_id"
    t.string  "image_dimensions", :limit => nil
  end

  add_index "ads_slots", ["name"], :name => "ads_slots_name_key", :unique => true

  create_table "ads_slots_instances", :force => true do |t|
    t.datetime "created_on",                     :null => false
    t.integer  "ads_slot_id",                    :null => false
    t.integer  "ad_id",                          :null => false
    t.boolean  "deleted",     :default => false, :null => false
  end

  create_table "ads_slots_portals", :force => true do |t|
    t.integer "ads_slot_id", :null => false
    t.integer "portal_id",   :null => false
  end

  create_table "advertisers", :force => true do |t|
    t.string   "name",       :limit => nil,                   :null => false
    t.string   "email",      :limit => nil,                   :null => false
    t.integer  "due_on_day", :limit => 2,                     :null => false
    t.datetime "created_on",                                  :null => false
    t.boolean  "active",                    :default => true, :null => false
  end

  add_index "advertisers", ["email"], :name => "advertisers_email_key", :unique => true
  add_index "advertisers", ["name"], :name => "advertisers_name_key", :unique => true

  create_table "allowed_competitions_participants", :force => true do |t|
    t.integer "competition_id", :null => false
    t.integer "participant_id", :null => false
  end

  create_table "anonymous_users", :force => true do |t|
    t.string   "session_id",  :limit => 32, :null => false
    t.datetime "lastseen_on",               :null => false
  end

  add_index "anonymous_users", ["lastseen_on"], :name => "anonymous_users_lastseen"
  add_index "anonymous_users", ["session_id"], :name => "anonymous_users_session_id_key", :unique => true

  create_table "autologin_keys", :force => true do |t|
    t.datetime "created_on",                :null => false
    t.string   "key",         :limit => 40
    t.integer  "user_id",                   :null => false
    t.datetime "lastused_on",               :null => false
  end

  add_index "autologin_keys", ["key"], :name => "autologin_keys_key", :unique => true
  add_index "autologin_keys", ["lastused_on"], :name => "autologin_keys_lastused_on"

  create_table "avatars", :force => true do |t|
    t.string   "name",              :limit => nil,                 :null => false
    t.integer  "level",                            :default => -1, :null => false
    t.string   "path",              :limit => nil
    t.integer  "faction_id"
    t.integer  "user_id"
    t.integer  "clan_id"
    t.datetime "created_on",                                       :null => false
    t.integer  "submitter_user_id",                                :null => false
  end

  add_index "avatars", ["clan_id"], :name => "avatars_clan_id"
  add_index "avatars", ["faction_id"], :name => "avatars_faction_id"
  add_index "avatars", ["name", "faction_id"], :name => "avatars_name_faction_id", :unique => true
  add_index "avatars", ["user_id"], :name => "avatars_user_id"

  create_table "babes", :force => true do |t|
    t.date    "date",     :null => false
    t.integer "image_id", :null => false
  end

  add_index "babes", ["date"], :name => "babes_date_key", :unique => true

  create_table "ban_requests", :force => true do |t|
    t.integer  "user_id",                                 :null => false
    t.integer  "banned_user_id",                          :null => false
    t.integer  "confirming_user_id"
    t.datetime "created_on",                              :null => false
    t.datetime "confirmed_on"
    t.string   "reason",                   :limit => nil, :null => false
    t.integer  "unban_user_id"
    t.integer  "unban_confirming_user_id"
    t.string   "reason_unban",             :limit => nil
    t.datetime "unban_created_on"
    t.datetime "unban_confirmed_on"
  end

  create_table "bazar_districts", :force => true do |t|
    t.string   "name",            :limit => nil, :null => false
    t.string   "code",            :limit => nil, :null => false
    t.string   "icon",            :limit => nil
    t.string   "building_top",    :limit => nil
    t.string   "building_middle", :limit => nil
    t.string   "building_bottom", :limit => nil
    t.datetime "created_on",                     :null => false
    t.datetime "updated_on",                     :null => false
  end

  add_index "bazar_districts", ["code"], :name => "bazar_districts_code_key", :unique => true
  add_index "bazar_districts", ["name"], :name => "bazar_districts_name_key", :unique => true

  create_table "bets", :force => true do |t|
    t.datetime "created_on",                                                                              :null => false
    t.datetime "updated_on",                                                                              :null => false
    t.integer  "user_id",                                                                                 :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_registered",                                                      :default => 0,     :null => false
    t.integer  "hits_anonymous",                                                       :default => 0,     :null => false
    t.integer  "cache_rating",           :limit => 2
    t.integer  "cache_rated_times",      :limit => 2
    t.integer  "cache_comments_count",                                                 :default => 0,     :null => false
    t.string   "title",                  :limit => nil,                                                   :null => false
    t.string   "description",            :limit => nil
    t.datetime "closes_on",                                                                               :null => false
    t.decimal  "total_ammount",                         :precision => 14, :scale => 2, :default => 0.0,   :null => false
    t.integer  "winning_bets_option_id"
    t.boolean  "cancelled",                                                            :default => false, :null => false
    t.boolean  "forfeit",                                                              :default => false, :null => false
    t.boolean  "tie",                                                                  :default => false, :null => false
    t.string   "log",                    :limit => nil
    t.integer  "state",                  :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                   :precision => 10, :scale => 2
    t.boolean  "closed",                                                               :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "bets", ["approved_by_user_id"], :name => "bets_approved_by_user_id"
  add_index "bets", ["state"], :name => "bets_state"
  add_index "bets", ["user_id"], :name => "bets_user_id"

  create_table "bets_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.string   "description",          :limit => nil
    t.integer  "last_updated_item_id"
    t.integer  "bets_count",                          :default => 0, :null => false
  end

  add_index "bets_categories", ["name", "parent_id"], :name => "bets_categories_unique", :unique => true

  create_table "bets_options", :force => true do |t|
    t.integer "bet_id",                                                :null => false
    t.string  "name",    :limit => nil,                                :null => false
    t.decimal "ammount",                :precision => 14, :scale => 2
  end

  create_table "bets_tickets", :force => true do |t|
    t.integer  "bets_option_id",                                :null => false
    t.integer  "user_id",                                       :null => false
    t.decimal  "ammount",        :precision => 14, :scale => 2
    t.datetime "created_on",                                    :null => false
  end

  add_index "bets_tickets", ["user_id"], :name => "bets_tickets_user_id"

  create_table "blogentries", :force => true do |t|
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "main",                                                                                  :null => false
    t.integer  "user_id",                                                                               :null => false
    t.string   "log",                  :limit => nil
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.boolean  "deleted",                                                            :default => false, :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "blogentries", ["state"], :name => "blogentries_state"
  add_index "blogentries", ["user_id", "deleted"], :name => "blogentries_published"

  create_table "cash_movements", :force => true do |t|
    t.string   "description",          :limit => nil,                                :null => false
    t.integer  "object_id_from"
    t.integer  "object_id_to"
    t.datetime "created_on",                                                         :null => false
    t.decimal  "ammount",                             :precision => 14, :scale => 2
    t.string   "object_id_from_class", :limit => nil
    t.string   "object_id_to_class",   :limit => nil
  end

  add_index "cash_movements", ["object_id_from", "object_id_from_class"], :name => "cash_movements_from"
  add_index "cash_movements", ["object_id_to", "object_id_to_class"], :name => "cash_movements_to"

  create_table "chatlines", :force => true do |t|
    t.string   "line",        :limit => nil,                    :null => false
    t.datetime "created_on",                                    :null => false
    t.integer  "user_id",                                       :null => false
    t.boolean  "sent_to_irc",                :default => false, :null => false
  end

  add_index "chatlines", ["created_on"], :name => "chatlines_created_on"

  create_table "clans", :force => true do |t|
    t.string   "name",                          :limit => nil,                                                   :null => false
    t.string   "tag",                           :limit => nil,                                                   :null => false
    t.boolean  "simple_mode",                                                                 :default => true,  :null => false
    t.string   "website_external",              :limit => nil
    t.datetime "created_on",                                                                                     :null => false
    t.string   "irc_channel",                   :limit => nil
    t.string   "irc_server",                    :limit => nil
    t.integer  "o3_websites_dynamicwebsite_id"
    t.string   "logo",                          :limit => nil
    t.text     "description"
    t.string   "competition_roster",            :limit => nil
    t.decimal  "cash",                                         :precision => 14, :scale => 2, :default => 0.0,   :null => false
    t.boolean  "deleted",                                                                     :default => false, :null => false
    t.integer  "members_count",                                                               :default => 0,     :null => false
    t.boolean  "website_activated",                                                           :default => false, :null => false
    t.integer  "creator_user_id"
    t.integer  "cache_popularity"
    t.integer  "ranking_popularity_pos"
  end

  add_index "clans", ["name"], :name => "clans_name_key", :unique => true
  add_index "clans", ["tag"], :name => "clans_tag"
  add_index "clans", ["tag"], :name => "clans_tag_key", :unique => true

  create_table "clans_friends", :force => true do |t|
    t.integer "from_clan_id",                    :null => false
    t.boolean "from_wants",   :default => false, :null => false
    t.integer "to_clan_id",                      :null => false
    t.boolean "to_wants",     :default => false, :null => false
  end

  create_table "clans_games", :id => false, :force => true do |t|
    t.integer "clan_id", :null => false
    t.integer "game_id", :null => false
  end

  add_index "clans_games", ["clan_id", "game_id"], :name => "clans_r_games_clan_game", :unique => true
  add_index "clans_games", ["clan_id"], :name => "clans_r_games_clan_id"
  add_index "clans_games", ["game_id"], :name => "clans_r_games_game_id"

  create_table "clans_groups", :force => true do |t|
    t.string  "name",                 :limit => nil, :null => false
    t.integer "clans_groups_type_id",                :null => false
    t.integer "clan_id"
  end

  create_table "clans_groups_types", :force => true do |t|
    t.string "name", :limit => nil, :null => false
  end

  add_index "clans_groups_types", ["name"], :name => "clans_groups_types_name"
  add_index "clans_groups_types", ["name"], :name => "clans_groups_types_name_key", :unique => true

  create_table "clans_groups_users", :id => false, :force => true do |t|
    t.integer "clans_group_id", :null => false
    t.integer "user_id",        :null => false
  end

  add_index "clans_groups_users", ["clans_group_id", "user_id"], :name => "clans_groups_r_users_group_user", :unique => true

  create_table "clans_logs_entries", :force => true do |t|
    t.string   "message",    :limit => nil
    t.integer  "clan_id",                   :null => false
    t.datetime "created_on",                :null => false
  end

  create_table "clans_movements", :force => true do |t|
    t.integer  "clan_id",                 :null => false
    t.integer  "user_id"
    t.integer  "direction",  :limit => 2, :null => false
    t.datetime "created_on",              :null => false
  end

  create_table "clans_sponsors", :force => true do |t|
    t.string  "name",    :limit => nil, :null => false
    t.integer "clan_id",                :null => false
    t.string  "url",     :limit => nil
    t.string  "image",   :limit => nil
  end

  add_index "clans_sponsors", ["clan_id", "name"], :name => "clans_sponsors_clan_id_name", :unique => true

  create_table "columns", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "description",                                                                           :null => false
    t.text     "main",                                                                                  :null => false
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.boolean  "deleted",                                                            :default => false, :null => false
    t.string   "home_image",           :limit => nil
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
    t.string   "source",               :limit => nil
  end

  add_index "columns", ["approved_by_user_id", "deleted"], :name => "columns_appr_and_not_deleted"
  add_index "columns", ["approved_by_user_id"], :name => "columns_approved_by_user_id"
  add_index "columns", ["state"], :name => "columns_state"
  add_index "columns", ["user_id"], :name => "columns_user_id"

  create_table "columns_categories", :force => true do |t|
    t.string  "name",                 :limit => nil,                :null => false
    t.integer "parent_id"
    t.integer "root_id"
    t.string  "code",                 :limit => nil
    t.string  "description",          :limit => nil
    t.integer "last_updated_item_id"
    t.integer "columns_count",                       :default => 0, :null => false
  end

  add_index "columns_categories", ["name", "parent_id"], :name => "columns_categories_unique", :unique => true

  create_table "comment_violation_opinions", :force => true do |t|
    t.integer  "user_id",                 :null => false
    t.integer  "comment_id",              :null => false
    t.integer  "cls",        :limit => 2, :null => false
    t.datetime "created_on",              :null => false
    t.datetime "updated_on",              :null => false
  end

  add_index "comment_violation_opinions", ["user_id", "comment_id"], :name => "comment_violation_opinion", :unique => true
  add_index "comment_violation_opinions", ["user_id"], :name => "comment_violation_opinions_user_id"

  create_table "comments", :force => true do |t|
    t.integer  "content_id",                                                 :null => false
    t.integer  "user_id",                                                    :null => false
    t.string   "host",                     :limit => nil,                    :null => false
    t.datetime "created_on",                                                 :null => false
    t.datetime "updated_on",                                                 :null => false
    t.text     "comment",                                                    :null => false
    t.boolean  "has_comments_valorations",                :default => false, :null => false
    t.integer  "portal_id"
    t.string   "cache_rating",             :limit => nil
    t.boolean  "netiquette_violation"
    t.string   "lastowner_version",        :limit => nil
    t.integer  "lastedited_by_user_id"
    t.boolean  "deleted",                                 :default => false, :null => false
    t.decimal  "random_v"
  end

  add_index "comments", ["content_id"], :name => "comments_content_id"
  add_index "comments", ["created_on", "content_id"], :name => "comments_created_on_content_id"
  add_index "comments", ["created_on"], :name => "comments_created_on"
  add_index "comments", ["has_comments_valorations", "user_id"], :name => "comments_has_comments_valorations_user_id"
  add_index "comments", ["random_v"], :name => "comments_random_v"
  add_index "comments", ["user_id", "created_on"], :name => "comments_user_id_created_on"

  create_table "comments_valorations", :force => true do |t|
    t.integer  "comment_id",                   :null => false
    t.integer  "user_id",                      :null => false
    t.datetime "created_on",                   :null => false
    t.integer  "comments_valorations_type_id", :null => false
    t.float    "weight",                       :null => false
    t.decimal  "randval"
  end

  add_index "comments_valorations", ["comment_id", "user_id"], :name => "comments_valorations_comment_id_user_id", :unique => true

  create_table "comments_valorations_types", :force => true do |t|
    t.string  "name",      :limit => nil, :null => false
    t.integer "direction", :limit => 2,   :null => false
  end

  add_index "comments_valorations_types", ["name"], :name => "comments_valorations_types_name_key", :unique => true

  create_table "competitions", :force => true do |t|
    t.string   "name",                              :limit => nil,                                                   :null => false
    t.text     "description"
    t.integer  "game_id",                                                                                            :null => false
    t.integer  "state",                             :limit => 2,                                  :default => 0,     :null => false
    t.text     "rules"
    t.integer  "competitions_participants_type_id",                                                                  :null => false
    t.integer  "default_maps_per_match",            :limit => 2
    t.boolean  "forced_maps",                                                                     :default => true,  :null => false
    t.integer  "random_map_selection_mode",         :limit => 2
    t.integer  "scoring_mode",                      :limit => 2,                                  :default => 0,     :null => false
    t.boolean  "pro",                                                                             :default => false, :null => false
    t.decimal  "cash",                                             :precision => 14, :scale => 2, :default => 0.0,   :null => false
    t.boolean  "force_guids",                                                                     :default => false, :null => false
    t.datetime "estimated_end_on"
    t.integer  "timetable_for_matches",             :limit => 2,                                  :default => 0,     :null => false
    t.string   "timetable_options",                 :limit => nil
    t.decimal  "fee",                                              :precision => 14, :scale => 2
    t.boolean  "invitational",                                                                    :default => false, :null => false
    t.string   "competitions_types_options",        :limit => nil
    t.datetime "created_on",                                                                                         :null => false
    t.datetime "closed_on"
    t.integer  "event_id"
    t.integer  "topics_category_id"
    t.string   "header_image",                      :limit => nil
    t.string   "type",                              :limit => nil,                                                   :null => false
    t.boolean  "send_notifications",                                                              :default => true,  :null => false
  end

  add_index "competitions", ["name"], :name => "competitions_name_key", :unique => true

  create_table "competitions_admins", :id => false, :force => true do |t|
    t.integer "competition_id", :null => false
    t.integer "user_id",        :null => false
  end

  create_table "competitions_games_maps", :id => false, :force => true do |t|
    t.integer "competition_id", :null => false
    t.integer "games_map_id",   :null => false
  end

  add_index "competitions_games_maps", ["competition_id", "games_map_id"], :name => "competitions_games_maps_uniq", :unique => true

  create_table "competitions_logs_entries", :force => true do |t|
    t.string   "message",        :limit => nil
    t.integer  "competition_id",                :null => false
    t.datetime "created_on",                    :null => false
  end

  create_table "competitions_matches", :force => true do |t|
    t.integer  "competition_id",                                                  :null => false
    t.integer  "participant1_id"
    t.integer  "participant2_id"
    t.integer  "result",                        :limit => 2
    t.boolean  "participant1_confirmed_result",                :default => false, :null => false
    t.boolean  "participant2_confirmed_result",                :default => false, :null => false
    t.boolean  "admin_confirmed_result",                       :default => false, :null => false
    t.integer  "stage",                         :limit => 2,   :default => 0,     :null => false
    t.integer  "maps",                          :limit => 2
    t.integer  "score_participant1"
    t.integer  "score_participant2"
    t.boolean  "accepted",                                     :default => true,  :null => false
    t.datetime "completed_on"
    t.datetime "created_on",                                                      :null => false
    t.datetime "play_on"
    t.integer  "event_id"
    t.boolean  "forfeit_participant1",                         :default => false, :null => false
    t.boolean  "forfeit_participant2",                         :default => false, :null => false
    t.string   "servers",                       :limit => nil
    t.string   "ladder_rules",                  :limit => nil
    t.datetime "updated_on",                                                      :null => false
  end

  add_index "competitions_matches", ["competition_id"], :name => "competitions_matches_competition_id"
  add_index "competitions_matches", ["event_id"], :name => "competitions_matches_event_id"
  add_index "competitions_matches", ["participant1_id"], :name => "competitions_matches_participant1_id"
  add_index "competitions_matches", ["participant2_id"], :name => "competitions_matches_participant2_id"

  create_table "competitions_matches_clans_players", :force => true do |t|
    t.integer  "competitions_match_id",       :null => false
    t.integer  "competitions_participant_id", :null => false
    t.integer  "user_id",                     :null => false
    t.datetime "created_on",                  :null => false
  end

  create_table "competitions_matches_games_maps", :force => true do |t|
    t.integer "competitions_match_id",      :null => false
    t.integer "games_map_id",               :null => false
    t.integer "partial_participant1_score"
    t.integer "partial_participant2_score"
  end

  create_table "competitions_matches_reports", :force => true do |t|
    t.integer  "competitions_match_id", :null => false
    t.integer  "user_id",               :null => false
    t.text     "report",                :null => false
    t.datetime "created_on",            :null => false
  end

  create_table "competitions_matches_uploads", :force => true do |t|
    t.integer  "competitions_match_id",                :null => false
    t.integer  "user_id",                              :null => false
    t.string   "file",                  :limit => nil
    t.string   "description",           :limit => nil
    t.datetime "created_on",                           :null => false
  end

  create_table "competitions_participants", :force => true do |t|
    t.integer  "competition_id",                                                  :null => false
    t.integer  "participant_id",                                                  :null => false
    t.integer  "competitions_participants_type_id", :limit => 2,                  :null => false
    t.string   "name",                              :limit => nil,                :null => false
    t.integer  "wins",                                             :default => 0, :null => false
    t.integer  "losses",                                           :default => 0, :null => false
    t.integer  "ties",                                             :default => 0, :null => false
    t.string   "roster",                            :limit => nil
    t.datetime "created_on",                                                      :null => false
    t.integer  "points"
    t.integer  "position",                                                        :null => false
  end

  add_index "competitions_participants", ["competition_id", "participant_id", "competitions_participants_type_id"], :name => "competitions_participants_uniq", :unique => true
  add_index "competitions_participants", ["competition_id"], :name => "competitions_participants_competition_id"

  create_table "competitions_participants_types", :force => true do |t|
    t.string "name", :limit => nil, :null => false
  end

  add_index "competitions_participants_types", ["name"], :name => "competitions_participants_types_name_key", :unique => true

  create_table "competitions_sponsors", :force => true do |t|
    t.string  "name",           :limit => nil, :null => false
    t.integer "competition_id",                :null => false
    t.string  "url",            :limit => nil
    t.string  "image",          :limit => nil
  end

  create_table "competitions_supervisors", :id => false, :force => true do |t|
    t.integer "competition_id", :null => false
    t.integer "user_id",        :null => false
  end

  add_index "competitions_supervisors", ["competition_id", "user_id"], :name => "competitions_supervisors_uniq", :unique => true

  create_table "content_ratings", :force => true do |t|
    t.integer  "user_id"
    t.string   "ip",         :limit => nil, :null => false
    t.datetime "created_on",                :null => false
    t.integer  "content_id",                :null => false
    t.integer  "rating",     :limit => 2,   :null => false
  end

  add_index "content_ratings", ["ip", "user_id", "created_on"], :name => "content_ratings_comb"
  add_index "content_ratings", ["user_id", "content_id"], :name => "content_ratings_user_id_content_id", :unique => true

  create_table "content_types", :force => true do |t|
    t.string "name", :limit => nil, :null => false
  end

  add_index "content_types", ["name"], :name => "content_types_name_key", :unique => true

  create_table "contents", :force => true do |t|
    t.integer  "content_type_id",                                     :null => false
    t.integer  "external_id",                                         :null => false
    t.datetime "updated_on",                                          :null => false
    t.string   "name",              :limit => nil,                    :null => false
    t.integer  "comments_count",                   :default => 0,     :null => false
    t.boolean  "is_public",                        :default => false, :null => false
    t.integer  "game_id"
    t.integer  "state",             :limit => 2,   :default => 0,     :null => false
    t.integer  "clan_id"
    t.datetime "created_on",                                          :null => false
    t.integer  "platform_id"
    t.string   "url",               :limit => nil
    t.integer  "user_id",                                             :null => false
    t.integer  "portal_id"
    t.integer  "bazar_district_id"
    t.boolean  "closed",                           :default => false, :null => false
    t.string   "source",            :limit => nil
  end

  add_index "contents", ["content_type_id", "external_id"], :name => "contents_content_type_id_key", :unique => true
  add_index "contents", ["created_on"], :name => "contents_created_on"
  add_index "contents", ["id", "state", "content_type_id"], :name => "contents_id_state_content_type_id"
  add_index "contents", ["is_public", "game_id"], :name => "contents_is_public_and_game_id"
  add_index "contents", ["is_public"], :name => "contents_is_public"
  add_index "contents", ["state", "clan_id"], :name => "contents_state_clan_id"
  add_index "contents", ["state"], :name => "contents_state"
  add_index "contents", ["url"], :name => "contents_url_key", :unique => true
  add_index "contents", ["user_id", "state"], :name => "contents_user_id_state"

  create_table "contents_locks", :force => true do |t|
    t.datetime "created_on", :null => false
    t.datetime "updated_on", :null => false
    t.integer  "content_id", :null => false
    t.integer  "user_id",    :null => false
  end

  add_index "contents_locks", ["content_id"], :name => "contents_locks_uniq", :unique => true

  create_table "contents_recommendations", :force => true do |t|
    t.datetime "created_on",                                         :null => false
    t.integer  "sender_user_id",                                     :null => false
    t.integer  "receiver_user_id",                                   :null => false
    t.integer  "content_id",                                         :null => false
    t.datetime "seen_on"
    t.boolean  "marked_as_bad",                   :default => false, :null => false
    t.float    "confidence"
    t.integer  "expected_rating",  :limit => 2
    t.string   "comment",          :limit => nil
  end

  add_index "contents_recommendations", ["content_id", "receiver_user_id"], :name => "contents_recommendations_seen_on_content_id_receiver_user_id"
  add_index "contents_recommendations", ["content_id", "sender_user_id", "receiver_user_id"], :name => "contents_recommendations_content_id_sender_user_id_receiver_use", :unique => true
  add_index "contents_recommendations", ["receiver_user_id", "marked_as_bad"], :name => "contents_recommendations_receiver_user_id_marked_as_bad"
  add_index "contents_recommendations", ["sender_user_id"], :name => "contents_recommendations_sender_user_id"

  create_table "contents_terms", :force => true do |t|
    t.integer  "content_id", :null => false
    t.integer  "term_id",    :null => false
    t.datetime "created_on", :null => false
  end

  add_index "contents_terms", ["content_id", "term_id"], :name => "contents_terms_uniq", :unique => true
  add_index "contents_terms", ["content_id"], :name => "contents_terms_content_id"
  add_index "contents_terms", ["term_id"], :name => "contents_terms_term_id"

  create_table "contents_versions", :force => true do |t|
    t.datetime "created_on", :null => false
    t.integer  "content_id", :null => false
    t.text     "data"
  end

  create_table "countries", :id => false, :force => true do |t|
    t.integer "id",                  :null => false
    t.string  "code", :limit => nil
    t.string  "name", :limit => nil
  end

  create_table "coverages", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "user_id",                                                                               :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.text     "description",                                                                           :null => false
    t.text     "main"
    t.integer  "event_id",                                                                              :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "coverages", ["approved_by_user_id"], :name => "events_news_approved_by_user_id"
  add_index "coverages", ["state"], :name => "events_news_state"
  add_index "coverages", ["user_id"], :name => "events_news_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",                  :default => 0
    t.integer  "attempts",                  :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue",      :limit => nil
  end

  create_table "demo_mirrors", :force => true do |t|
    t.integer "demo_id",                :null => false
    t.string  "url",     :limit => nil, :null => false
  end

  create_table "demos", :force => true do |t|
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "user_id",                                                                               :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.boolean  "deleted",                                                            :default => false, :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.string   "title",                :limit => nil,                                                   :null => false
    t.string   "description",          :limit => nil
    t.integer  "entity1_local_id"
    t.integer  "entity2_local_id"
    t.string   "entity1_external",     :limit => nil
    t.string   "entity2_external",     :limit => nil
    t.integer  "games_map_id"
    t.integer  "event_id"
    t.integer  "pov_type",             :limit => 2
    t.integer  "pov_entity",           :limit => 2
    t.string   "file",                 :limit => nil
    t.string   "file_hash_md5",        :limit => nil
    t.integer  "downloaded_times",                                                   :default => 0,     :null => false
    t.integer  "file_size",            :limit => 8
    t.integer  "games_mode_id"
    t.integer  "games_version_id"
    t.integer  "demotype",             :limit => 2
    t.date     "played_on"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "demos", ["approved_by_user_id", "deleted"], :name => "demos_approved_by_user_id_deleted"
  add_index "demos", ["approved_by_user_id"], :name => "demos_approved_by_user_id"
  add_index "demos", ["file"], :name => "demos_file", :unique => true
  add_index "demos", ["file_hash_md5"], :name => "demos_hash_md5", :unique => true
  add_index "demos", ["state"], :name => "demos_state"
  add_index "demos", ["user_id"], :name => "demos_user_id"

  create_table "demos_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.string   "description",          :limit => nil
    t.integer  "last_updated_item_id"
    t.integer  "demos_count",                         :default => 0, :null => false
  end

  add_index "demos_categories", ["name", "parent_id"], :name => "demos_categories_unique", :unique => true

  create_table "download_mirrors", :force => true do |t|
    t.integer "download_id",                :null => false
    t.string  "url",         :limit => nil, :null => false
  end

  create_table "downloaded_downloads", :force => true do |t|
    t.integer  "download_id",                    :null => false
    t.datetime "created_on",                     :null => false
    t.string   "ip",              :limit => nil, :null => false
    t.string   "session_id",      :limit => nil
    t.string   "referer",         :limit => nil
    t.integer  "user_id"
    t.string   "download_cookie", :limit => 32
  end

  create_table "downloads", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "description"
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.string   "file",                 :limit => nil
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.boolean  "essential",                                                          :default => false, :null => false
    t.integer  "downloaded_times",                                                   :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.string   "file_hash_md5",        :limit => 32
    t.integer  "clan_id"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "downloads", ["approved_by_user_id"], :name => "downloads_approved_by_user_id"
  add_index "downloads", ["file"], :name => "downloads_path_key", :unique => true
  add_index "downloads", ["file_hash_md5"], :name => "downloads_hash_md5"
  add_index "downloads", ["state"], :name => "downloads_state"
  add_index "downloads", ["user_id"], :name => "downloads_user_id"

  create_table "downloads_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.string   "description",          :limit => nil
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.integer  "downloads_count",                     :default => 0, :null => false
    t.integer  "last_updated_item_id"
    t.integer  "clan_id"
  end

  add_index "downloads_categories", ["name", "parent_id"], :name => "downloads_categories_unique", :unique => true

  create_table "dudes", :force => true do |t|
    t.date    "date",     :null => false
    t.integer "image_id", :null => false
  end

  add_index "dudes", ["date"], :name => "dudes_date_key", :unique => true

  create_table "events", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.text     "description"
    t.datetime "starts_on",                                                                             :null => false
    t.datetime "ends_on",                                                                               :null => false
    t.string   "website",              :limit => nil
    t.integer  "parent_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "user_id",                                                                               :null => false
    t.integer  "approved_by_user_id"
    t.boolean  "deleted",                                                            :default => false, :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.integer  "clan_id"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "events", ["approved_by_user_id", "deleted"], :name => "events_appr_and_not_deleted"
  add_index "events", ["approved_by_user_id"], :name => "events_approved_by_user_id"
  add_index "events", ["state"], :name => "events_state"
  add_index "events", ["user_id"], :name => "events_user_id"

  create_table "events_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.string   "description",          :limit => nil
    t.integer  "last_updated_item_id"
    t.integer  "events_count",                        :default => 0, :null => false
    t.integer  "clan_id"
  end

  create_table "events_users", :id => false, :force => true do |t|
    t.integer "event_id", :null => false
    t.integer "user_id",  :null => false
  end

  create_table "factions", :force => true do |t|
    t.string   "name",                  :limit => nil,                                                   :null => false
    t.integer  "boss_user_id"
    t.integer  "underboss_user_id"
    t.string   "building_bottom",       :limit => nil
    t.string   "building_top",          :limit => nil
    t.string   "building_middle",       :limit => nil
    t.string   "description",           :limit => nil
    t.string   "why_join",              :limit => nil
    t.string   "code",                  :limit => nil
    t.integer  "members_count",                                                       :default => 0,     :null => false
    t.decimal  "cash",                                 :precision => 14, :scale => 2, :default => 0.0,   :null => false
    t.boolean  "is_platform",                                                         :default => false, :null => false
    t.datetime "created_on",                                                                             :null => false
    t.decimal  "cache_member_cohesion"
  end

  add_index "factions", ["building_bottom"], :name => "factions_building_bottom_key", :unique => true
  add_index "factions", ["building_middle"], :name => "factions_building_middle_key", :unique => true
  add_index "factions", ["building_top"], :name => "factions_building_top_key", :unique => true
  add_index "factions", ["code"], :name => "factions_code_key", :unique => true
  add_index "factions", ["name"], :name => "factions_name_key", :unique => true

  create_table "factions_banned_users", :force => true do |t|
    t.integer  "faction_id",                    :null => false
    t.integer  "user_id",                       :null => false
    t.datetime "created_on",                    :null => false
    t.string   "reason",         :limit => nil
    t.integer  "banner_user_id",                :null => false
  end

  add_index "factions_banned_users", ["faction_id", "user_id"], :name => "factions_banned_users_fu", :unique => true

  create_table "factions_capos", :force => true do |t|
    t.integer "faction_id", :null => false
    t.integer "user_id",    :null => false
  end

  add_index "factions_capos", ["faction_id", "user_id"], :name => "factions_capos_uniq", :unique => true

  create_table "factions_editors", :force => true do |t|
    t.integer "faction_id",      :null => false
    t.integer "user_id",         :null => false
    t.integer "content_type_id", :null => false
  end

  add_index "factions_editors", ["faction_id", "user_id", "content_type_id"], :name => "factions_editors_uniq", :unique => true

  create_table "factions_headers", :force => true do |t|
    t.integer  "faction_id",                      :null => false
    t.string   "name",             :limit => nil, :null => false
    t.datetime "lasttime_used_on"
  end

  add_index "factions_headers", ["faction_id", "name"], :name => "factions_headers_names_faction_id", :unique => true
  add_index "factions_headers", ["lasttime_used_on"], :name => "factions_headers_lasttime_used_on"

  create_table "factions_links", :force => true do |t|
    t.integer "faction_id",                :null => false
    t.string  "name",       :limit => nil, :null => false
    t.string  "url",        :limit => nil, :null => false
    t.string  "image",      :limit => nil
  end

  add_index "factions_links", ["faction_id", "name"], :name => "factions_links_names_faction_id", :unique => true

  create_table "factions_portals", :id => false, :force => true do |t|
    t.integer "faction_id", :null => false
    t.integer "portal_id",  :null => false
  end

  create_table "faq_categories", :force => true do |t|
    t.string  "name",      :limit => nil, :null => false
    t.integer "position"
    t.integer "parent_id"
    t.integer "root_id"
  end

  add_index "faq_categories", ["name"], :name => "faq_categories_name_key", :unique => true

  create_table "faq_entries", :force => true do |t|
    t.string   "question",        :limit => nil, :null => false
    t.string   "answer",          :limit => nil, :null => false
    t.integer  "faq_category_id",                :null => false
    t.datetime "updated_on",                     :null => false
    t.integer  "position"
  end

  create_table "friends_recommendations", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.integer  "recommended_user_id",                :null => false
    t.datetime "created_on",                         :null => false
    t.datetime "updated_on"
    t.boolean  "added_as_friend"
    t.string   "reason",              :limit => nil
  end

  add_index "friends_recommendations", ["user_id", "added_as_friend"], :name => "friends_recommendations_user_id_undecided"
  add_index "friends_recommendations", ["user_id", "recommended_user_id"], :name => "friends_recommendations_uniq", :unique => true

  create_table "friendships", :force => true do |t|
    t.integer  "sender_user_id",                         :null => false
    t.integer  "receiver_user_id"
    t.datetime "created_on",                             :null => false
    t.datetime "accepted_on"
    t.string   "receiver_email",          :limit => nil
    t.string   "invitation_text",         :limit => nil
    t.string   "external_invitation_key", :limit => 32
  end

  add_index "friendships", ["external_invitation_key"], :name => "friends_users_external_invitation_key_key", :unique => true
  add_index "friendships", ["sender_user_id", "receiver_user_id"], :name => "friends_users_uniq", :unique => true

  create_table "funthings", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.string   "description",          :limit => nil
    t.string   "main",                 :limit => nil
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "funthings", ["main"], :name => "funthings_url_key", :unique => true
  add_index "funthings", ["state"], :name => "funthings_state"
  add_index "funthings", ["title"], :name => "funthings_title_uniq", :unique => true

  create_table "gamersmafiageist_codes", :force => true do |t|
    t.integer  "user_id",                            :null => false
    t.datetime "created_on",                         :null => false
    t.string   "code",                :limit => nil
    t.string   "survey_edition_date", :limit => nil, :null => false
  end

  add_index "gamersmafiageist_codes", ["code"], :name => "gamersmafiageist_codes_code_key", :unique => true
  add_index "gamersmafiageist_codes", ["user_id", "survey_edition_date"], :name => "gamersmafiageist_codes_user_edition"

  create_table "games", :force => true do |t|
    t.string  "name",        :limit => nil,                    :null => false
    t.string  "code",        :limit => nil,                    :null => false
    t.boolean "has_guids",                  :default => false, :null => false
    t.string  "guid_format", :limit => nil
  end

  add_index "games", ["code"], :name => "games_code_unique", :unique => true
  add_index "games", ["name"], :name => "games_name_key", :unique => true

  create_table "games_maps", :force => true do |t|
    t.string  "name",        :limit => nil, :null => false
    t.integer "game_id",                    :null => false
    t.integer "download_id"
    t.string  "screenshot",  :limit => nil
  end

  add_index "games_maps", ["name", "game_id"], :name => "games_maps_name_game_id", :unique => true

  create_table "games_modes", :force => true do |t|
    t.string  "name",        :limit => nil, :null => false
    t.integer "game_id",                    :null => false
    t.integer "entity_type", :limit => 2
  end

  add_index "games_modes", ["name", "game_id"], :name => "games_modes_uniq", :unique => true

  create_table "games_platforms", :id => false, :force => true do |t|
    t.integer "game_id",     :null => false
    t.integer "platform_id", :null => false
  end

  create_table "games_users", :id => false, :force => true do |t|
    t.integer "game_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "games_users", ["game_id"], :name => "games_users_game_id"
  add_index "games_users", ["user_id", "game_id"], :name => "games_users_uniq", :unique => true
  add_index "games_users", ["user_id"], :name => "games_users_user_id"

  create_table "games_versions", :force => true do |t|
    t.string  "version", :limit => nil, :null => false
    t.integer "game_id",                :null => false
  end

  add_index "games_versions", ["version", "game_id"], :name => "games_versions_uniq", :unique => true

  create_table "global_vars", :force => true do |t|
    t.integer  "online_anonymous",                                              :default => 0, :null => false
    t.integer  "online_registered",                                             :default => 0, :null => false
    t.string   "svn_revision",                                   :limit => nil
    t.datetime "ads_slots_updated_on",                                                         :null => false
    t.datetime "gmtv_channels_updated_on",                                                     :null => false
    t.integer  "pending_contents",                                              :default => 0, :null => false
    t.datetime "portals_updated_on",                                                           :null => false
    t.decimal  "max_cache_valorations_weights_on_self_comments"
  end

  create_table "gmtv_broadcast_messages", :force => true do |t|
    t.string   "message",   :limit => nil, :null => false
    t.datetime "starts_on",                :null => false
    t.datetime "ends_on",                  :null => false
  end

  create_table "gmtv_channels", :force => true do |t|
    t.datetime "created_on",                :null => false
    t.datetime "updated_on",                :null => false
    t.integer  "user_id",                   :null => false
    t.integer  "faction_id"
    t.string   "file",       :limit => nil
    t.string   "screenshot", :limit => nil
  end

  create_table "groups", :force => true do |t|
    t.string   "name",          :limit => nil, :null => false
    t.datetime "created_on",                   :null => false
    t.string   "description",   :limit => nil
    t.integer  "owner_user_id"
  end

  add_index "groups", ["name"], :name => "groups_name_key", :unique => true

  create_table "groups_messages", :force => true do |t|
    t.datetime "created_on",                :null => false
    t.string   "title",      :limit => nil
    t.string   "main",       :limit => nil
    t.integer  "parent_id"
    t.integer  "root_id"
    t.integer  "user_id"
  end

  create_table "ias", :id => false, :force => true do |t|
    t.integer  "id"
    t.string   "login",                                      :limit => 80
    t.string   "password",                                   :limit => 40
    t.string   "validkey",                                   :limit => 40
    t.string   "email",                                      :limit => 100
    t.string   "newemail",                                   :limit => 100
    t.string   "ipaddr",                                     :limit => 15
    t.datetime "created_on"
    t.datetime "updated_at"
    t.string   "firstname",                                  :limit => nil
    t.string   "lastname",                                   :limit => nil
    t.binary   "image"
    t.datetime "lastseen_on"
    t.integer  "faction_id"
    t.datetime "faction_last_changed_on"
    t.integer  "avatar_id"
    t.string   "city",                                       :limit => nil
    t.string   "homepage",                                   :limit => nil
    t.integer  "sex",                                        :limit => 2
    t.string   "msn",                                        :limit => nil
    t.string   "icq",                                        :limit => nil
    t.date     "birthday"
    t.integer  "cache_karma_points"
    t.string   "irc",                                        :limit => nil
    t.integer  "country_id"
    t.string   "photo",                                      :limit => nil
    t.string   "hw_mouse",                                   :limit => nil
    t.string   "hw_processor",                               :limit => nil
    t.string   "hw_motherboard",                             :limit => nil
    t.string   "hw_ram",                                     :limit => nil
    t.string   "hw_hdd",                                     :limit => nil
    t.string   "hw_graphiccard",                             :limit => nil
    t.string   "hw_soundcard",                               :limit => nil
    t.string   "hw_headphones",                              :limit => nil
    t.string   "hw_monitor",                                 :limit => nil
    t.string   "hw_connection",                              :limit => nil
    t.text     "description"
    t.boolean  "is_superadmin"
    t.integer  "comments_count"
    t.integer  "referer_user_id"
    t.integer  "cache_faith_points"
    t.boolean  "notifications_global"
    t.boolean  "notifications_newmessages"
    t.boolean  "notifications_newregistrations"
    t.boolean  "notifications_trackerupdates"
    t.string   "xfire",                                      :limit => nil
    t.integer  "cache_unread_messages"
    t.integer  "resurrected_by_user_id"
    t.datetime "resurrection_started_on"
    t.boolean  "using_tracker"
    t.string   "secret",                                     :limit => 32
    t.decimal  "cash",                                                      :precision => 14, :scale => 2
    t.datetime "lastcommented_on"
    t.integer  "global_bans"
    t.integer  "last_clan_id"
    t.integer  "antiflood_level",                            :limit => 2
    t.integer  "last_competition_id"
    t.string   "competition_roster",                         :limit => nil
    t.boolean  "enable_competition_indicator"
    t.boolean  "is_hq"
    t.boolean  "enable_profile_signatures"
    t.integer  "profile_signatures_count"
    t.string   "wii_code",                                   :limit => 16
    t.boolean  "email_public"
    t.string   "gamertag",                                   :limit => nil
    t.string   "googletalk",                                 :limit => nil
    t.string   "yahoo_im",                                   :limit => nil
    t.boolean  "notifications_newprofilesignature"
    t.boolean  "tracker_autodelete_old_contents"
    t.boolean  "comment_adds_to_tracker_enabled"
    t.integer  "cache_remaining_rating_slots"
    t.boolean  "has_seen_tour"
    t.boolean  "is_bot"
    t.string   "admin_permissions",                          :limit => nil
    t.integer  "state",                                      :limit => 2
    t.boolean  "cache_is_faction_leader"
    t.datetime "profile_last_updated_on"
    t.string   "visitor_id",                                 :limit => nil
    t.integer  "comments_valorations_type_id"
    t.decimal  "comments_valorations_strength",                             :precision => 10, :scale => 2
    t.boolean  "enable_comments_sig"
    t.string   "comments_sig",                               :limit => nil
    t.boolean  "comment_show_sigs"
    t.boolean  "has_new_friend_requests"
    t.string   "default_portal",                             :limit => nil
    t.string   "emblems_mask",                               :limit => nil
    t.float    "random_id"
    t.boolean  "is_staff"
    t.integer  "pending_slog"
    t.integer  "ranking_karma_pos"
    t.integer  "ranking_faith_pos"
    t.integer  "ranking_popularity_pos"
    t.integer  "cache_popularity"
    t.boolean  "login_is_ne_unfriendly"
    t.decimal  "cache_valorations_weights_on_self_comments"
    t.float    "default_comments_valorations_weight"
  end

  create_table "images", :force => true do |t|
    t.string   "description",          :limit => nil
    t.string   "file",                 :limit => nil
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.string   "file_hash_md5",        :limit => 32
    t.integer  "clan_id"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  add_index "images", ["approved_by_user_id"], :name => "images_approved_by_user_id"
  add_index "images", ["file"], :name => "images_path_key", :unique => true
  add_index "images", ["file_hash_md5"], :name => "images_hash_md5"
  add_index "images", ["state"], :name => "images_state"
  add_index "images", ["user_id"], :name => "images_user_id"

  create_table "images_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.string   "description",          :limit => nil
    t.integer  "last_updated_item_id"
    t.integer  "images_count",                        :default => 0, :null => false
    t.integer  "clan_id"
  end

  add_index "images_categories", ["name", "parent_id"], :name => "images_categories_unique", :unique => true

  create_table "interviews", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "description",                                                                           :null => false
    t.text     "main",                                                                                  :null => false
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.string   "home_image",           :limit => nil
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
    t.string   "source",               :limit => nil
  end

  add_index "interviews", ["approved_by_user_id"], :name => "interviews_approved_by_user_id"
  add_index "interviews", ["state"], :name => "interviews_state"
  add_index "interviews", ["user_id"], :name => "interviews_user_id"

  create_table "interviews_categories", :force => true do |t|
    t.string  "name",                 :limit => nil,                :null => false
    t.integer "parent_id"
    t.integer "root_id"
    t.string  "code",                 :limit => nil
    t.string  "description",          :limit => nil
    t.integer "last_updated_item_id"
    t.integer "interviews_count",                    :default => 0, :null => false
  end

  add_index "interviews_categories", ["name", "parent_id"], :name => "interviews_categories_unique", :unique => true

  create_table "ip_bans", :force => true do |t|
    t.string   "ip",         :limit => nil, :null => false
    t.datetime "created_on",                :null => false
    t.datetime "expires_on"
    t.string   "comment",    :limit => nil
    t.integer  "user_id"
  end

  create_table "ip_passwords_resets_requests", :force => true do |t|
    t.string   "ip",         :limit => nil, :null => false
    t.datetime "created_on",                :null => false
  end

  add_index "ip_passwords_resets_requests", ["ip", "created_on"], :name => "ip_passwords_resets_requests_ip_created_on"

  create_table "macropolls", :force => true do |t|
    t.integer  "poll_id",                                          :null => false
    t.integer  "user_id"
    t.text     "answers"
    t.datetime "created_on",                                       :null => false
    t.string   "ipaddr",     :limit => nil, :default => "0.0.0.0", :null => false
    t.string   "host",       :limit => nil
  end

  create_table "macropolls_2007_1", :force => true do |t|
    t.string  "lacantidaddecontenidosquesepublicanenlawebteparece",              :limit => nil
    t.string  "__sabesquepuedesenviarcontenidos_",                               :limit => nil
    t.string  "__sabesquepuedesdecidirsiuncontenidosepublicaono_",               :limit => nil
    t.string  "__echasenfaltafuncionesimportantesenlaweb_",                      :limit => nil
    t.string  "__estassuscritoafeedsrss_",                                       :limit => nil
    t.string  "participasencompeticiones_clanbase",                              :limit => nil
    t.string  "__tegustaelmanga_anime_",                                         :limit => nil
    t.string  "larapidezdecargadelaspaginasteparece",                            :limit => nil
    t.string  "lasecciondeforosteparece",                                        :limit => nil
    t.string  "tesientesidentificadoconlaweb",                                   :limit => nil
    t.string  "prefeririasnovermasqueloscontenidosdetujuego",                    :limit => nil
    t.string  "__quecreesquedeberiamosmejorardeformamasurgenteenlaweb_",         :limit => nil
    t.string  "ellogodelawebtegusta",                                            :limit => nil
    t.string  "__estasenalgunclan_",                                             :limit => nil
    t.string  "eldisenodelawebteparece",                                         :limit => nil
    t.string  "elnumerodefuncionesdelawebteparece_bis_",                         :limit => nil
    t.string  "laactituddelosadministradores_bossesymoderadoresdelawebteparece", :limit => nil
    t.string  "__tienesalgunavideoconsola_",                                     :limit => nil
    t.string  "siofreciesemosdenuevoelsistemadewebsparaclanes___creesquetuclan", :limit => nil
    t.string  "sipudiesesleregalariasalwebmasterunbilletea",                     :limit => nil
    t.string  "elambienteenloscomentarioses",                                    :limit => nil
    t.string  "elnumerodefuncionesdelawebteparece",                              :limit => nil
    t.string  "seguneltiempoquelededicasalosjuegosteconsiderasunjugador",        :limit => nil
    t.string  "lacantidaddepublicidadqueapareceenlawebteparece",                 :limit => nil
    t.string  "lalabordelosadministradores_bossesymoderadoresdelawebteparece",   :limit => nil
    t.string  "__sabesquepuedescreartuspropiascompeticionesoparticiparencompet", :limit => nil
    t.string  "lascabecerasteparecen",                                           :limit => nil
    t.string  "tuopiniongeneralsobrelawebes",                                    :limit => nil
    t.string  "razonprincipalporlaquevisitaslaweb",                              :limit => nil
    t.string  "lacalidaddeloscontenidosteparece",                                :limit => nil
    t.string  "lasecciondebabes_dudestegusta",                                   :limit => nil
    t.string  "__quetendriaquetenerlawebparaquefueseperfectaparati_",            :limit => nil
    t.string  "__deentrelaswebsdejuegosquevisitasfrecuentementedondenossituari", :limit => nil
    t.integer "user_id"
    t.string  "created_on",                                                      :limit => nil, :null => false
    t.string  "ipaddr",                                                          :limit => nil, :null => false
    t.string  "host",                                                            :limit => nil
  end

  create_table "messages", :force => true do |t|
    t.integer  "user_id_from",                                       :null => false
    t.integer  "user_id_to",                                         :null => false
    t.string   "title",            :limit => nil,                    :null => false
    t.text     "message",                                            :null => false
    t.datetime "created_on",                                         :null => false
    t.boolean  "is_read",                         :default => false, :null => false
    t.integer  "in_reply_to"
    t.boolean  "has_replies",                     :default => false, :null => false
    t.integer  "message_type",     :limit => 2,   :default => 0,     :null => false
    t.boolean  "sender_deleted",                  :default => false, :null => false
    t.boolean  "receiver_deleted",                :default => false, :null => false
    t.integer  "thread_id"
  end

  add_index "messages", ["user_id_to"], :name => "messages_user_id_is_read"

  create_table "ne_references", :force => true do |t|
    t.datetime "created_on",                      :null => false
    t.datetime "referenced_on",                   :null => false
    t.string   "entity_class",     :limit => nil, :null => false
    t.integer  "entity_id",                       :null => false
    t.string   "referencer_class", :limit => nil, :null => false
    t.integer  "referencer_id",                   :null => false
  end

  add_index "ne_references", ["entity_class", "entity_id", "referencer_class", "referencer_id"], :name => "ne_references_uniq", :unique => true
  add_index "ne_references", ["entity_class", "entity_id"], :name => "ne_references_entity"
  add_index "ne_references", ["referencer_class", "referencer_id"], :name => "ne_references_referencer"

  create_table "news", :force => true do |t|
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "user_id",                                                                               :null => false
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "description",                                                                           :null => false
    t.text     "main"
    t.integer  "approved_by_user_id"
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.integer  "clan_id"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
    t.string   "source",               :limit => nil
  end

  add_index "news", ["approved_by_user_id"], :name => "news_approved_by_user_id"
  add_index "news", ["state"], :name => "news_state"
  add_index "news", ["user_id"], :name => "news_user_id"

  create_table "news_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.string   "description",          :limit => nil
    t.integer  "last_updated_item_id"
    t.integer  "news_count",                          :default => 0, :null => false
    t.integer  "clan_id"
    t.string   "file",                 :limit => nil
  end

  add_index "news_categories", ["name", "parent_id"], :name => "news_categories_unique", :unique => true

  create_table "outstanding_entities", :force => true do |t|
    t.integer "entity_id",                :null => false
    t.integer "portal_id"
    t.date    "active_on",                :null => false
    t.string  "type",      :limit => nil, :null => false
    t.string  "reason",    :limit => nil
  end

  add_index "outstanding_entities", ["type", "portal_id", "active_on"], :name => "outstanding_entities_uniq", :unique => true

  create_table "platforms", :force => true do |t|
    t.string "name", :limit => nil, :null => false
    t.string "code", :limit => nil, :null => false
  end

  add_index "platforms", ["code"], :name => "platforms_code_key", :unique => true
  add_index "platforms", ["name"], :name => "platforms_name_key", :unique => true

  create_table "platforms_users", :id => false, :force => true do |t|
    t.integer "user_id",     :null => false
    t.integer "platform_id", :null => false
  end

  add_index "platforms_users", ["platform_id"], :name => "platforms_users_platform_id"
  add_index "platforms_users", ["user_id", "platform_id"], :name => "platforms_users_platform_id_user_id", :unique => true
  add_index "platforms_users", ["user_id"], :name => "platforms_users_user_id"

  create_table "polls", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "user_id",                                                                               :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.datetime "starts_on",                                                                             :null => false
    t.datetime "ends_on",                                                                               :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.integer  "clan_id"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
    t.integer  "polls_votes_count",                                                  :default => 0,     :null => false
  end

  add_index "polls", ["approved_by_user_id"], :name => "polls_approved_by_user_id"
  add_index "polls", ["state"], :name => "polls_state"
  add_index "polls", ["title"], :name => "polls_title_key", :unique => true
  add_index "polls", ["user_id"], :name => "polls_user_id"

  create_table "polls_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                :null => false
    t.integer  "parent_id"
    t.string   "description",          :limit => nil
    t.datetime "updated_on",                                         :null => false
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.integer  "polls_count",                         :default => 0, :null => false
    t.integer  "last_updated_item_id"
    t.integer  "clan_id"
  end

  add_index "polls_categories", ["code", "parent_id"], :name => "polls_categories_code_parent_id", :unique => true
  add_index "polls_categories", ["name", "parent_id"], :name => "polls_categories_name_parent_id", :unique => true

  create_table "polls_options", :force => true do |t|
    t.integer "poll_id",                                         :null => false
    t.string  "name",              :limit => nil,                :null => false
    t.integer "polls_votes_count",                :default => 0, :null => false
    t.integer "position"
  end

  add_index "polls_options", ["poll_id", "name"], :name => "polls_options_poll_id_key", :unique => true

  create_table "polls_votes", :force => true do |t|
    t.integer  "polls_option_id",                :null => false
    t.integer  "user_id"
    t.string   "remote_ip",       :limit => nil, :null => false
    t.datetime "created_on",                     :null => false
  end

  create_table "portal_headers", :force => true do |t|
    t.datetime "date",               :null => false
    t.integer  "factions_header_id", :null => false
    t.integer  "portal_id",          :null => false
  end

  create_table "portal_hits", :force => true do |t|
    t.integer "portal_id"
    t.date    "date",                     :null => false
    t.integer "hits",      :default => 0, :null => false
  end

  add_index "portal_hits", ["portal_id", "date"], :name => "portal_hits_uniq", :unique => true

  create_table "portals", :force => true do |t|
    t.string   "name",                    :limit => nil,                               :null => false
    t.string   "code",                    :limit => nil,                               :null => false
    t.string   "type",                    :limit => nil, :default => "FactionsPortal", :null => false
    t.string   "fqdn",                    :limit => nil
    t.string   "options",                 :limit => nil
    t.integer  "clan_id"
    t.datetime "created_on",                                                           :null => false
    t.integer  "skin_id"
    t.integer  "default_gmtv_channel_id"
    t.integer  "cache_recent_hits_count"
    t.string   "factions_portal_home",    :limit => nil
    t.string   "small_header",            :limit => nil
  end

  add_index "portals", ["code"], :name => "portals_code_key", :unique => true
  add_index "portals", ["name", "code", "type"], :name => "portals_name_code_type", :unique => true

  create_table "portals_skins", :id => false, :force => true do |t|
    t.integer "portal_id", :null => false
    t.integer "skin_id",   :null => false
  end

  create_table "potds", :force => true do |t|
    t.date    "date",               :null => false
    t.integer "image_id",           :null => false
    t.integer "portal_id"
    t.integer "images_category_id"
    t.integer "term_id"
  end

  add_index "potds", ["date", "portal_id", "images_category_id"], :name => "potds_uniq", :unique => true

  create_table "products", :force => true do |t|
    t.string   "name",        :limit => nil,                                                  :null => false
    t.decimal  "price",                      :precision => 14, :scale => 2,                   :null => false
    t.datetime "created_on",                                                                  :null => false
    t.string   "description", :limit => nil
    t.datetime "updated_on",                                                                  :null => false
    t.string   "cls",         :limit => nil,                                                  :null => false
    t.boolean  "enabled",                                                   :default => true, :null => false
  end

  add_index "products", ["cls"], :name => "products_cls_key", :unique => true
  add_index "products", ["name"], :name => "products_name_key", :unique => true

  create_table "profile_signatures", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.integer  "signer_user_id",                :null => false
    t.string   "signature",      :limit => nil, :null => false
    t.datetime "updated_on",                    :null => false
  end

  add_index "profile_signatures", ["user_id", "signer_user_id"], :name => "profile_signatures_user_id_signer_user_id", :unique => true
  add_index "profile_signatures", ["user_id"], :name => "profile_signatures_user_id"

  create_table "publishing_decisions", :force => true do |t|
    t.integer  "user_id",                       :null => false
    t.datetime "created_on",                    :null => false
    t.datetime "updated_on",                    :null => false
    t.integer  "content_id",                    :null => false
    t.boolean  "publish",                       :null => false
    t.decimal  "user_weight",                   :null => false
    t.string   "deny_reason",    :limit => nil
    t.boolean  "is_right"
    t.string   "accept_comment", :limit => nil
  end

  add_index "publishing_decisions", ["user_id", "content_id"], :name => "publishing_decisions_user_id_content_id", :unique => true

  create_table "publishing_personalities", :force => true do |t|
    t.integer "user_id",                          :null => false
    t.integer "content_type_id",                  :null => false
    t.decimal "experience",      :default => 0.0
  end

  add_index "publishing_personalities", ["user_id", "content_type_id"], :name => "publishing_personalities_user_id_content_type_id", :unique => true

  create_table "questions", :force => true do |t|
    t.string   "title",                      :limit => nil,                                                   :null => false
    t.text     "description"
    t.datetime "created_on",                                                                                  :null => false
    t.datetime "updated_on",                                                                                  :null => false
    t.integer  "user_id",                                                                                     :null => false
    t.integer  "accepted_answer_comment_id"
    t.integer  "hits_anonymous",                                                           :default => 0,     :null => false
    t.integer  "hits_registered",                                                          :default => 0,     :null => false
    t.integer  "cache_rating",               :limit => 2
    t.integer  "cache_rated_times",          :limit => 2
    t.integer  "cache_comments_count",                                                     :default => 0,     :null => false
    t.string   "log",                        :limit => nil
    t.integer  "state",                      :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                       :precision => 10, :scale => 2
    t.integer  "approved_by_user_id"
    t.decimal  "ammount",                                   :precision => 10, :scale => 2
    t.datetime "answered_on"
    t.boolean  "closed",                                                                   :default => false, :null => false
    t.integer  "unique_content_id"
    t.integer  "answer_selected_by_user_id"
  end

  add_index "questions", ["state"], :name => "questions_state"
  add_index "questions", ["user_id"], :name => "questions_user_id"

  create_table "questions_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                    :null => false
    t.integer  "forum_category_id"
    t.integer  "questions_count",                     :default => 0,     :null => false
    t.datetime "updated_on"
    t.integer  "parent_id"
    t.string   "description",          :limit => nil
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.integer  "last_question_id"
    t.integer  "comments_count",                      :default => 0
    t.integer  "last_updated_item_id"
    t.float    "avg_popularity"
    t.integer  "clan_id"
    t.boolean  "nohome",                              :default => false, :null => false
  end

  add_index "questions_categories", ["code", "name", "parent_id"], :name => "questions_categories_code_name_parent_id", :unique => true

  create_table "recruitment_ads", :force => true do |t|
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "user_id",                                                                               :null => false
    t.integer  "clan_id"
    t.integer  "game_id",                                                                               :null => false
    t.string   "levels",               :limit => nil
    t.integer  "country_id"
    t.text     "main"
    t.boolean  "deleted",                                                            :default => false, :null => false
    t.string   "title",                :limit => nil,                                                   :null => false
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
  end

  create_table "refered_hits", :force => true do |t|
    t.integer  "user_id",                   :null => false
    t.datetime "created_on",                :null => false
    t.string   "ipaddr",     :limit => nil, :null => false
    t.string   "referer",    :limit => nil, :null => false
  end

  add_index "refered_hits", ["user_id"], :name => "refered_hits_user_id"

  create_table "reviews", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "description",                                                                           :null => false
    t.text     "main",                                                                                  :null => false
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.string   "home_image",           :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
    t.string   "source",               :limit => nil
  end

  add_index "reviews", ["approved_by_user_id"], :name => "reviews_approved_by_user_id"
  add_index "reviews", ["state"], :name => "reviews_state"
  add_index "reviews", ["user_id"], :name => "reviews_user_id"

  create_table "reviews_categories", :force => true do |t|
    t.string  "name",                 :limit => nil,                :null => false
    t.integer "parent_id"
    t.integer "root_id"
    t.string  "code",                 :limit => nil
    t.string  "description",          :limit => nil
    t.integer "last_updated_item_id"
    t.integer "reviews_count",                       :default => 0, :null => false
  end

  add_index "reviews_categories", ["name", "parent_id"], :name => "reviews_categories_unique", :unique => true

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version",                                 :null => false
    t.integer "_Slony-I_gamersmafia_rowID", :limit => 8, :null => false
  end

  add_index "schema_info", ["_Slony-I_gamersmafia_rowID"], :name => "schema_info__Slony-I_gamersmafia_rowID_key", :unique => true
  add_index "schema_info", ["version"], :name => "schema_info_version_key", :unique => true

  create_table "sent_emails", :force => true do |t|
    t.string   "message_key",       :limit => nil, :null => false
    t.string   "title",             :limit => nil
    t.datetime "created_on",                       :null => false
    t.datetime "first_read_on"
    t.string   "sender",            :limit => nil
    t.string   "recipient",         :limit => nil
    t.integer  "recipient_user_id"
  end

  add_index "sent_emails", ["created_on"], :name => "sent_emails_created_on"
  add_index "sent_emails", ["message_key"], :name => "sent_emails_message_key_key", :unique => true

  create_table "silenced_emails", :force => true do |t|
    t.string "email", :limit => nil, :null => false
  end

  add_index "silenced_emails", ["email"], :name => "silenced_emails_email_key", :unique => true

  create_table "skin_textures", :force => true do |t|
    t.datetime "created_on",                               :null => false
    t.integer  "skin_id",                                  :null => false
    t.integer  "texture_id",                               :null => false
    t.integer  "textured_element_position",                :null => false
    t.integer  "texture_skin_position",                    :null => false
    t.string   "user_config",               :limit => nil
    t.string   "element",                   :limit => nil, :null => false
  end

  create_table "skins", :force => true do |t|
    t.string  "name",                :limit => nil,                    :null => false
    t.string  "hid",                 :limit => nil,                    :null => false
    t.integer "user_id",                                               :null => false
    t.boolean "is_public",                          :default => false, :null => false
    t.string  "type",                :limit => nil,                    :null => false
    t.string  "file",                :limit => nil
    t.integer "version",                            :default => 0,     :null => false
    t.string  "intelliskin_header",  :limit => nil
    t.string  "intelliskin_favicon", :limit => nil
  end

  add_index "skins", ["hid"], :name => "skins_hid_key", :unique => true

  create_table "skins_files", :force => true do |t|
    t.integer "skin_id",                :null => false
    t.string  "file",    :limit => nil, :null => false
  end

  create_table "slog_entries", :force => true do |t|
    t.datetime "created_on",                      :null => false
    t.integer  "type_id",                         :null => false
    t.string   "info",             :limit => nil, :null => false
    t.string   "headline",         :limit => nil, :null => false
    t.text     "request"
    t.integer  "reporter_user_id"
    t.integer  "reviewer_user_id"
    t.string   "long_version",     :limit => nil
    t.string   "short_version",    :limit => nil
    t.datetime "completed_on"
    t.integer  "scope"
  end

  add_index "slog_entries", ["completed_on"], :name => "slog_entries_completed_on"
  add_index "slog_entries", ["headline"], :name => "slog_entries_headline"
  add_index "slog_entries", ["scope"], :name => "slog_entries_scope"
  add_index "slog_entries", ["type_id"], :name => "slog_type_id"

  create_table "slog_visits", :id => false, :force => true do |t|
    t.integer  "user_id",      :null => false
    t.datetime "lastvisit_on", :null => false
  end

  create_table "sold_products", :force => true do |t|
    t.integer  "product_id",                                                                  :null => false
    t.integer  "user_id",                                                                     :null => false
    t.datetime "created_on",                                                                  :null => false
    t.decimal  "price_paid",                :precision => 14, :scale => 2,                    :null => false
    t.boolean  "used",                                                     :default => false, :null => false
    t.string   "type",       :limit => nil
  end

  create_table "staff_candidates", :force => true do |t|
    t.integer  "staff_position_id",                                   :null => false
    t.datetime "created_on",                                          :null => false
    t.datetime "updated_on",                                          :null => false
    t.integer  "user_id",                                             :null => false
    t.string   "key_result1",       :limit => nil
    t.string   "key_result2",       :limit => nil
    t.string   "key_result3",       :limit => nil
    t.boolean  "is_winner",                        :default => false, :null => false
    t.datetime "term_starts_on"
    t.datetime "term_ends_on"
  end

  create_table "staff_canditate_votes", :force => true do |t|
    t.integer  "user_id",            :null => false
    t.datetime "created_on",         :null => false
    t.integer  "staff_candidate_id", :null => false
  end

  create_table "staff_positions", :force => true do |t|
    t.integer  "staff_type_id",                                               :null => false
    t.string   "state",              :limit => nil, :default => "unassigned", :null => false
    t.datetime "term_started_on"
    t.datetime "term_ends_on"
    t.integer  "staff_candidate_id"
  end

  create_table "staff_types", :force => true do |t|
    t.string "name", :limit => nil, :null => false
  end

  add_index "staff_types", ["name"], :name => "staff_types_name_key", :unique => true

  create_table "terms", :force => true do |t|
    t.string  "name",                 :limit => nil,                :null => false
    t.string  "slug",                 :limit => nil,                :null => false
    t.string  "description",          :limit => nil
    t.integer "parent_id"
    t.integer "game_id"
    t.integer "platform_id"
    t.integer "bazar_district_id"
    t.integer "clan_id"
    t.integer "contents_count",                      :default => 0, :null => false
    t.integer "last_updated_item_id"
    t.integer "comments_count",                      :default => 0, :null => false
    t.integer "root_id"
    t.string  "taxonomy",             :limit => nil
  end

  add_index "terms", ["game_id", "bazar_district_id", "platform_id", "clan_id", "taxonomy", "parent_id", "name"], :name => "terms_name_uniq"
  add_index "terms", ["game_id", "bazar_district_id", "platform_id", "clan_id", "taxonomy", "parent_id", "slug"], :name => "terms_slug_uniq"
  add_index "terms", ["parent_id"], :name => "terms_parent_id"
  add_index "terms", ["root_id", "parent_id", "taxonomy"], :name => "terms_root_id_parent_id_taxonomy"
  add_index "terms", ["root_id"], :name => "terms_root_id"
  add_index "terms", ["slug"], :name => "terms_slug_toplevel", :unique => true

  create_table "textures", :force => true do |t|
    t.string   "name",                    :limit => nil
    t.string   "generator",               :limit => nil, :null => false
    t.datetime "created_on",                             :null => false
    t.string   "valid_element_selectors", :limit => nil
  end

  add_index "textures", ["name"], :name => "textures_name_key", :unique => true

  create_table "topics", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "main",                                                                                  :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "user_id",                                                                               :null => false
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.boolean  "closed",                                                             :default => false, :null => false
    t.boolean  "sticky",                                                             :default => false, :null => false
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.datetime "moved_on"
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.integer  "clan_id"
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.integer  "unique_content_id"
  end

  add_index "topics", ["state"], :name => "forum_topics_state"
  add_index "topics", ["user_id"], :name => "forum_topics_user_id"

  create_table "topics_categories", :force => true do |t|
    t.string   "name",                 :limit => nil,                    :null => false
    t.integer  "forum_category_id"
    t.integer  "topics_count",                        :default => 0,     :null => false
    t.datetime "updated_on"
    t.integer  "parent_id"
    t.string   "description",          :limit => nil
    t.integer  "root_id"
    t.string   "code",                 :limit => nil
    t.integer  "last_topic_id"
    t.integer  "comments_count",                      :default => 0
    t.integer  "last_updated_item_id"
    t.float    "avg_popularity"
    t.integer  "clan_id"
    t.boolean  "nohome",                              :default => false, :null => false
  end

  add_index "topics_categories", ["code", "name", "parent_id"], :name => "forum_forums_code_name_parent_id", :unique => true

  create_table "tracker_items", :force => true do |t|
    t.integer  "content_id",                              :null => false
    t.integer  "user_id",                                 :null => false
    t.datetime "lastseen_on",                             :null => false
    t.boolean  "is_tracked",           :default => false, :null => false
    t.datetime "notification_sent_on"
  end

  add_index "tracker_items", ["content_id", "user_id", "lastseen_on", "is_tracked"], :name => "tracker_items_full"
  add_index "tracker_items", ["content_id", "user_id"], :name => "tracker_items_content_id_user_id", :unique => true
  add_index "tracker_items", ["id"], :name => "tracker_items_pkey", :unique => true
  add_index "tracker_items", ["user_id", "is_tracked"], :name => "tracker_items_user_id_is_tracked"

  create_table "treated_visitors", :id => false, :force => true do |t|
    t.integer "id",                        :null => false
    t.integer "ab_test_id",                :null => false
    t.string  "visitor_id", :limit => nil, :null => false
    t.integer "treatment",                 :null => false
    t.integer "user_id"
  end

  add_index "treated_visitors", ["ab_test_id", "visitor_id", "treatment"], :name => "treated_visitors_multi"
  add_index "treated_visitors", ["ab_test_id", "visitor_id"], :name => "treated_visitors_per_test", :unique => true

  create_table "tterms", :id => false, :force => true do |t|
    t.integer "id"
    t.string  "name",      :limit => nil
    t.string  "slug",      :limit => nil
    t.string  "taxonomy",  :limit => nil
    t.integer "parent_id"
    t.integer "root_id"
  end

  create_table "tutorials", :force => true do |t|
    t.string   "title",                :limit => nil,                                                   :null => false
    t.text     "description",                                                                           :null => false
    t.text     "main",                                                                                  :null => false
    t.integer  "user_id",                                                                               :null => false
    t.datetime "created_on",                                                                            :null => false
    t.datetime "updated_on",                                                                            :null => false
    t.integer  "approved_by_user_id"
    t.integer  "hits_anonymous",                                                     :default => 0,     :null => false
    t.integer  "hits_registered",                                                    :default => 0,     :null => false
    t.string   "home_image",           :limit => nil
    t.integer  "cache_rating",         :limit => 2
    t.integer  "cache_rated_times",    :limit => 2
    t.integer  "cache_comments_count",                                               :default => 0,     :null => false
    t.string   "log",                  :limit => nil
    t.integer  "state",                :limit => 2,                                  :default => 0,     :null => false
    t.decimal  "cache_weighted_rank",                 :precision => 10, :scale => 2
    t.boolean  "closed",                                                             :default => false, :null => false
    t.integer  "unique_content_id"
    t.string   "source",               :limit => nil
  end

  add_index "tutorials", ["approved_by_user_id"], :name => "tutorials_approved_by_user_id"
  add_index "tutorials", ["state"], :name => "tutorials_state"
  add_index "tutorials", ["user_id"], :name => "tutorials_user_id"

  create_table "tutorials_categories", :force => true do |t|
    t.string  "name",                 :limit => nil,                :null => false
    t.integer "parent_id"
    t.integer "root_id"
    t.string  "code",                 :limit => nil
    t.string  "description",          :limit => nil
    t.integer "last_updated_item_id"
    t.integer "tutorials_count",                     :default => 0
  end

  add_index "tutorials_categories", ["name", "parent_id"], :name => "tutorials_categories_unique", :unique => true

  create_table "user_login_changes", :force => true do |t|
    t.integer  "user_id",                   :null => false
    t.datetime "created_on",                :null => false
    t.string   "old_login",  :limit => nil, :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                      :limit => 80
    t.string   "password",                                   :limit => 40
    t.string   "validkey",                                   :limit => 40
    t.string   "email",                                      :limit => 100,                                :default => "",      :null => false
    t.string   "newemail",                                   :limit => 100
    t.string   "ipaddr",                                     :limit => 15,                                 :default => ""
    t.datetime "created_on",                                                                                                    :null => false
    t.datetime "updated_at",                                                                                                    :null => false
    t.string   "firstname",                                  :limit => nil,                                :default => ""
    t.string   "lastname",                                   :limit => nil,                                :default => ""
    t.binary   "image"
    t.datetime "lastseen_on",                                                                                                   :null => false
    t.integer  "faction_id"
    t.datetime "faction_last_changed_on"
    t.integer  "avatar_id"
    t.string   "city",                                       :limit => nil
    t.string   "homepage",                                   :limit => nil
    t.integer  "sex",                                        :limit => 2
    t.string   "msn",                                        :limit => nil
    t.string   "icq",                                        :limit => nil
    t.date     "birthday"
    t.integer  "cache_karma_points"
    t.string   "irc",                                        :limit => nil
    t.integer  "country_id"
    t.string   "photo",                                      :limit => nil
    t.string   "hw_mouse",                                   :limit => nil
    t.string   "hw_processor",                               :limit => nil
    t.string   "hw_motherboard",                             :limit => nil
    t.string   "hw_ram",                                     :limit => nil
    t.string   "hw_hdd",                                     :limit => nil
    t.string   "hw_graphiccard",                             :limit => nil
    t.string   "hw_soundcard",                               :limit => nil
    t.string   "hw_headphones",                              :limit => nil
    t.string   "hw_monitor",                                 :limit => nil
    t.string   "hw_connection",                              :limit => nil
    t.text     "description"
    t.boolean  "is_superadmin",                                                                            :default => false,   :null => false
    t.integer  "comments_count",                                                                           :default => 0,       :null => false
    t.integer  "referer_user_id"
    t.integer  "cache_faith_points"
    t.boolean  "notifications_global",                                                                     :default => true,    :null => false
    t.boolean  "notifications_newmessages",                                                                :default => true,    :null => false
    t.boolean  "notifications_newregistrations",                                                           :default => true,    :null => false
    t.boolean  "notifications_trackerupdates",                                                             :default => true,    :null => false
    t.string   "xfire",                                      :limit => nil
    t.integer  "cache_unread_messages",                                                                    :default => 0
    t.integer  "resurrected_by_user_id"
    t.datetime "resurrection_started_on"
    t.boolean  "using_tracker",                                                                            :default => false,   :null => false
    t.string   "secret",                                     :limit => 32
    t.decimal  "cash",                                                      :precision => 14, :scale => 2, :default => 0.0,     :null => false
    t.datetime "lastcommented_on"
    t.integer  "global_bans",                                                                              :default => 0,       :null => false
    t.integer  "last_clan_id"
    t.integer  "antiflood_level",                            :limit => 2,                                  :default => -1,      :null => false
    t.integer  "last_competition_id"
    t.string   "competition_roster",                         :limit => nil
    t.boolean  "enable_competition_indicator",                                                             :default => false,   :null => false
    t.boolean  "is_hq",                                                                                    :default => false,   :null => false
    t.boolean  "enable_profile_signatures",                                                                :default => false,   :null => false
    t.integer  "profile_signatures_count",                                                                 :default => 0,       :null => false
    t.string   "wii_code",                                   :limit => 16
    t.boolean  "email_public",                                                                             :default => false,   :null => false
    t.string   "gamertag",                                   :limit => nil
    t.string   "googletalk",                                 :limit => nil
    t.string   "yahoo_im",                                   :limit => nil
    t.boolean  "notifications_newprofilesignature",                                                        :default => true,    :null => false
    t.boolean  "tracker_autodelete_old_contents",                                                          :default => true,    :null => false
    t.boolean  "comment_adds_to_tracker_enabled",                                                          :default => true,    :null => false
    t.integer  "cache_remaining_rating_slots"
    t.boolean  "has_seen_tour",                                                                            :default => false,   :null => false
    t.boolean  "is_bot",                                                                                   :default => false,   :null => false
    t.string   "admin_permissions",                          :limit => nil,                                :default => "00000", :null => false
    t.integer  "state",                                      :limit => 2,                                  :default => 0,       :null => false
    t.boolean  "cache_is_faction_leader",                                                                  :default => false,   :null => false
    t.datetime "profile_last_updated_on"
    t.string   "visitor_id",                                 :limit => nil
    t.integer  "comments_valorations_type_id"
    t.decimal  "comments_valorations_strength",                             :precision => 10, :scale => 2
    t.boolean  "enable_comments_sig",                                                                      :default => false,   :null => false
    t.string   "comments_sig",                               :limit => nil
    t.boolean  "comment_show_sigs"
    t.boolean  "has_new_friend_requests",                                                                  :default => false,   :null => false
    t.string   "default_portal",                             :limit => nil
    t.string   "emblems_mask",                               :limit => nil
    t.float    "random_id"
    t.boolean  "is_staff",                                                                                 :default => false,   :null => false
    t.integer  "pending_slog",                                                                             :default => 0,       :null => false
    t.integer  "ranking_karma_pos"
    t.integer  "ranking_faith_pos"
    t.integer  "ranking_popularity_pos"
    t.integer  "cache_popularity"
    t.boolean  "login_is_ne_unfriendly",                                                                   :default => false,   :null => false
    t.decimal  "cache_valorations_weights_on_self_comments"
    t.float    "default_comments_valorations_weight",                                                      :default => 1.0,     :null => false
  end

  add_index "users", ["cache_remaining_rating_slots"], :name => "users_cache_remaning"
  add_index "users", ["comments_sig"], :name => "users_comments_sig", :unique => true
  add_index "users", ["email", "id"], :name => "users_email_id"
  add_index "users", ["faction_id"], :name => "users_faction_id"
  add_index "users", ["ipaddr"], :name => "users_lower_all"
  add_index "users", ["lastseen_on"], :name => "users_lastseen"
  add_index "users", ["login_is_ne_unfriendly"], :name => "users_login_ne_unfriendly"
  add_index "users", ["random_id"], :name => "users_random_id"
  add_index "users", ["secret"], :name => "users_secret", :unique => true
  add_index "users", ["state"], :name => "users_state"
  add_index "users", ["validkey"], :name => "users_validkey", :unique => true

  create_table "users_actions", :force => true do |t|
    t.datetime "created_on",                :null => false
    t.integer  "user_id"
    t.integer  "type_id",                   :null => false
    t.string   "data",       :limit => nil
    t.integer  "object_id"
  end

  add_index "users_actions", ["created_on"], :name => "users_actions_created_on"

  create_table "users_contents_tags", :force => true do |t|
    t.datetime "created_on",                   :null => false
    t.integer  "user_id",                      :null => false
    t.integer  "content_id",                   :null => false
    t.integer  "term_id",                      :null => false
    t.string   "original_name", :limit => nil, :null => false
  end

  add_index "users_contents_tags", ["content_id"], :name => "users_contents_tags_content_id"
  add_index "users_contents_tags", ["term_id"], :name => "users_contents_tags_term_id"
  add_index "users_contents_tags", ["user_id"], :name => "users_contents_tags_user_id"

  create_table "users_emblems", :force => true do |t|
    t.date    "created_on",                :null => false
    t.integer "user_id"
    t.string  "emblem",     :limit => nil, :null => false
    t.string  "details",    :limit => nil
  end

  add_index "users_emblems", ["created_on"], :name => "users_emblems_created_on"
  add_index "users_emblems", ["user_id"], :name => "users_emblems_user_id"

  create_table "users_guids", :force => true do |t|
    t.string   "guid",       :limit => nil, :null => false
    t.integer  "game_id",                   :null => false
    t.integer  "user_id",                   :null => false
    t.datetime "created_on",                :null => false
    t.string   "reason",     :limit => nil
  end

  add_index "users_guids", ["guid", "game_id"], :name => "users_guids_uniq", :unique => true

  create_table "users_lastseen_ips", :force => true do |t|
    t.datetime "created_on",                 :null => false
    t.datetime "lastseen_on",                :null => false
    t.integer  "user_id",                    :null => false
    t.string   "ip",          :limit => nil, :null => false
  end

  create_table "users_newsfeeds", :force => true do |t|
    t.datetime "created_on",                     :null => false
    t.integer  "user_id"
    t.string   "summary",         :limit => nil, :null => false
    t.integer  "users_action_id"
  end

  add_index "users_newsfeeds", ["created_on", "user_id"], :name => "users_newsfeeds_created_on_user_id"
  add_index "users_newsfeeds", ["created_on"], :name => "users_newsfeeds_created_on"

  create_table "users_preferences", :force => true do |t|
    t.integer "user_id",                :null => false
    t.string  "name",    :limit => nil, :null => false
    t.string  "value",   :limit => nil
  end

  add_index "users_preferences", ["user_id", "name"], :name => "users_preferences_user_id_name", :unique => true

  create_table "users_roles", :force => true do |t|
    t.integer  "user_id",                   :null => false
    t.string   "role",       :limit => nil, :null => false
    t.string   "role_data",  :limit => nil
    t.datetime "created_on",                :null => false
  end

  add_index "users_roles", ["role", "role_data"], :name => "users_roles_role_role_data"
  add_index "users_roles", ["role"], :name => "users_roles_role"
  add_index "users_roles", ["user_id", "role", "role_data"], :name => "users_roles_uniq", :unique => true
  add_index "users_roles", ["user_id"], :name => "users_roles_user_id"

end
