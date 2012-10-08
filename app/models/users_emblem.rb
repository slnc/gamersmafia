# -*- encoding : utf-8 -*-
class UsersEmblem < ActiveRecord::Base
  T_COMMENTS_COUNT_1 = 10
  T_COMMENTS_COUNT_2 = 500
  T_COMMENTS_COUNT_3 = 7500
  T_THE_BEAST_KARMA_POINTS = 100000
  T_COMMENT_VALORATIONS_1 = 1
  T_COMMENT_VALORATIONS_2 = 100
  T_COMMENT_VALORATIONS_2_MATCHING_USERS = 7
  T_COMMENT_VALORATIONS_3 = 5000
  T_COMMENT_VALORATIONS_3_MATCHING_USERS = 10
  T_REFERER_1 = 1
  T_REFERER_2 = 25
  T_REFERER_3 = 100

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
          :description => (
              "#{T_COMMENTS_COUNT_1} comentarios visibles."),
      },

      "comments_count_2" => {
          :frequency => "unfrequent",
          :name => "Parlanchín",
          :description => (
              "#{T_COMMENTS_COUNT_2} comentarios visibles por defecto."),
      },

      "comments_count_3" => {
          :frequency => "rare",
          :name => "Gran Orador",
          :description => (
              "#{T_COMMENTS_COUNT_3} comentarios visibles por defecto."),
      },

      "comments_valorations_1" => {
          :frequency => "common",
          :name => "Asertivo",
          :description => "#{T_COMMENT_VALORATIONS_1} comentario valorado.",
      },

      "comments_valorations_2" => {
          :frequency => "unfrequent",
          :name => "Sentencioso",
          :description => (
              "#{T_COMMENT_VALORATIONS_2} comentarios valorados en comentarios
              con al menos #{T_COMMENT_VALORATIONS_2_MATCHING_USERS}
              valoraciones."),
      },

      "comments_valorations_3" => {
          :frequency => "rare",
          :name => "Dogmático",
          :description => (
              "#{T_COMMENT_VALORATIONS_3} comentarios valorados en comentarios
              con al menos #{T_COMMENT_VALORATIONS_3_MATCHING_USERS}
              valoraciones."),
      },

      "user_referer_1" => {
          :frequency => "common",
          :name => "Puerta",
          :description => (
              "#{T_REFERER_1} usuario referido activo durante al menos el
               primer mes."),
      },

      "user_referer_2" => {
          :frequency => "unfrequent",
          :name => "Sacerdote",
          :description => (
              "#{T_REFERER_2} usuarios referidos activos durante al menos el
               primer mes."),
      },

      "user_referer_3" => {
          :frequency => "rare",
          :name => "Agente Smith",
          :description => (
              "#{T_REFERER_3} usuarios referidos activos durante al menos el
               primer mes."),
      },

      "the_beast" => {
          :frequency => "legendary",
          :name => "La Bestia",
          :description => "#{T_THE_BEAST_KARMA_POINTS} puntos de karma.",
      },
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
