# -*- encoding : utf-8 -*-
class UsersEmblem < ActiveRecord::Base
  T_COMMENTS_COUNT_1 = 50
  T_COMMENTS_COUNT_2 = 500
  T_COMMENTS_COUNT_3 = 5000

  FREQ_NAME = {
      "common" => "común",
      "legendary" => "legendario",
      "rare" => "raro",
      "special" => "especial",
      "unfrequent" => "poco frecuente",
  }

  SORTED_DECREASE_FREQUENCIES = %w(
      common
      unfrequent
      rare
      legendary
      special
  )

  EMBLEMS_INFO = {
      "comments_count_1" => {
          :frequency => "common",
          :name => "Hablador",
          :description => "50 comentarios publicados"},

      "comments_count_2" => {
          :frequency => "unfrequent",
          :name => "Parlanchín",
          :description => "500 comentarios publicados"},

      "comments_count_3" => {
          :frequency => "rare",
          :name => "Gran Orador",
          :description => "5000 comentarios publicados"},
  }


  VALID_EMBLEMS = EMBLEMS_INFO.keys

  before_save :check_valid_emblem
  belongs_to :user
  validates_presence_of :user_id
  validates_presence_of :emblem
  validates_uniqueness_of :emblem, :scope => :user_id

  after_create :reset_user_mask
  after_destroy :reset_user_mask

  scope :emblem,
        lambda {|emblem|
            {:conditions => ["emblem = ?", emblem]}
        }

  def self.inline_html_from_info(info)
    "<div class=\"emblem sprite1 #{info[:frequency]}\">
       <div class=\"name\" title=\"#{info[:description]}\">#{info[:name]}</div>
    </div>"
  end

  def reset_user_mask
    self.user.update_column("emblems_mask", nil)
  end

  def name
    EMBLEMS_INFO[self.emblem][:name]
  end

  def frequency
    EMBLEMS_INFO[self.emblem][:frequency]
  end

  def inline_html
    UsersEmblem.inline_html_from_info(EMBLEMS_INFO[self.emblem])
  end

  protected
  def check_valid_emblem
    VALID_EMBLEMS.include?(self.emblem)
  end
end
