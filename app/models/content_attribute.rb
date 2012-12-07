class ContentAttribute < ActiveRecord::Base
  belongs_to :content

  # Don't change these ids without changing existing content_attributes.
  VALID_ATTRIBUTES = {
      :cancelled => 1, # bet, bool
      :closes_on => 2, # bet, timestamp
      :forfeit => 3, # bet, bool
      :tie => 4, # bet, bool
      :total_ammount => 5, # bet, numeric(14, 2)
      :winning_bets_option_id => 6, # bet, int
      :file_hash_md5 => 7, # image, varchar
      :file => 8, # image, varchar
      :downloaded_times => 9, # download, int
      :essential => 10, # download, bool
      :file_hash_md5 => 11, # download, varchar
      :file => 12, # download, varchar
      :sticky => 13, #topic, bool
      :moved_on => 14, #topic, timestamp
      :starts_on => 15, # poll, timestamp
      :ends_on => 16, # poll, timestamp
      :polls_votes_count => 17, # poll, int
      :event_id => 18, # (event, coverage), int
      :home_image => 19, # column, interview, review, tutorial, varchar)
      :entity1_local_id => 20, # demo, int
      :entity2_local_id => 21, # demo, int
      :entity1_external => 22, # demo, varchar
      :entity2_external => 23, # demo, varchar
      :games_map_id => 24, # demo, int
      :event_id => 25, # demo, int
      :pov_type => 26, # demo, int
      :pov_entity => 27, # demo, int
      :file => 28, # demo, varchar
      :file_hash_md5 => 29, # demo, varchar
      :downloaded_times => 30, # demo, int
      :file_size => 31, # demo, bigint
      :games_mode_id => 32, # demo, int
      :games_version_id => 33, # demo, int
      :demotype => 34, # demo, int
      :played_on => 35, # demo, date
      :ammount => 36, # question, numeric(10, 2)
      :answered_on => 37, # question, timestamp
      :answer_selected_by_user_id => 38, # question, int
      :country_id => 39, # recruitment_ad, int
      :levels => 40, # recruitment_ad, varchar
      :clan_id => 41, # recruitment_ad, int
      :game_id => 42, # recruitment_ad, int
  }

  before_save :check_attribute_id

  private
  def check_attribute_id
    if !VALID_ATTRIBUTES.values.include?(self.attribute_id)
      raise "Invalid attribute_id: #{self.attribute_id}"
    end
  end
end
