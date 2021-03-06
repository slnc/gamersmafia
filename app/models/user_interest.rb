# -*- encoding : utf-8 -*-
class UserInterest < ActiveRecord::Base
  VALID_ENTITY_CLASSES = %w(
    Term
  )
  validates_uniqueness_of :entity_id, :scope => [:user_id, :entity_type_class]
  validates_presence_of :menu_shortcut
  validates_format_of :menu_shortcut,
    :with => /^[a-z0-9':[:space:]_-]{1,36}$/i,
    :message => ("Caracteres inválidos: solo se permiten números, letras,
                  espacios y guiones")

  scope :show_in_menu, :conditions => "show_in_menu = 't'"

  scope :interest_tuple,
    lambda { |entity_type_class, entity_id|
                 {
                   :conditions => ["entity_type_class = ? AND entity_id = ?",
                                   entity_type_class, entity_id]
                 }
  }

  belongs_to :user
  before_validation :populate_menu_shortcut
  validate :specified_interest_is_valid

  def self.build_interest_profile(user)
    term_frequencies = {}
    term_totals = {}
    User.db_query("
      SELECT
        content_id,
        term_id,
        (SELECT count(*)
         FROM contents_terms
         WHERE term_id = contents_terms.term_id
         AND created_on >= NOW() - '3 months'::interval) AS recent_contents
      FROM contents_terms
      WHERE content_id IN (
        SELECT content_id
        FROM tracker_items
        WHERE user_id = #{user.id})").each do |dbr|
      term_id = dbr['term_id'].to_i
      if !term_frequencies.include?(term_id)
        term_totals[term_id] = dbr['recent_contents'].to_i
        term_frequencies[term_id] = 0
      end
      term_frequencies[term_id] += 1
    end
    threshold = 0.01
    puts "user_id term_id frequency likelihood_visit"
    new_interests = []
    max_new_interests = 10
    term_frequencies.sort_by { |term_id, frequency| frequency}.reverse.each do |term_id, frequency|
      # We ignore terms that have very low frequency either for the user or for
      # the term. We picked this numbers based just on a reasonable guess.
      next if frequency <= 3 || term_totals[term_id] < 10
      likelihood_visit = frequency.to_f / term_totals[term_id]
      puts "#{user.id}\t#{term_id}\t#{frequency}\t#{likelihood_visit}"
      if likelihood_visit >= threshold
        new_interests << user.user_interests.create(
            :entity_type_class => "Term", :entity_id => term_id)
      end
      break if new_interests.size >= max_new_interests
    end

    return if new_interests.size == 0

    names = new_interests.collect {|interest| interest.entity_name}
    names = names.sort_by {|name| name.downcase }

    Notification.create({
        :user_id => user.id,
        :sender_user_id => Ias.jabba.id,
        :type_id => Notification::AUTOMATIC_INTERESTS_CREATED,
        :description => (
            "&quot;#{Ias.random_huttese_sentence}.&quot; - Jabba dice que le" +
            " parece que te interesan los siguientes temas: " +
            " #{names.join(", ")}.<br /><br />" +
            " <a href=\"/cuenta/cuenta/intereses\">Configura tus temas de" +
            " interés</a>.")
    })
  end

  def self.game_ids_of_interest(user)
    self.ids_of_interest(user, "Game")
  end

  def self.gaming_platform_ids_of_interest(user)
    self.ids_of_interest(user, "GamingPlatform")
  end

  def self.bazar_district_ids_of_interest(user)
    self.ids_of_interest(user, "BazarDistrict")
  end

  def self.ids_of_interest(user, taxonomy)
    table_name = ActiveSupport::Inflector::tableize(taxonomy)
    User.db_query("
      SELECT id
      FROM #{table_name}
      WHERE name IN (
        SELECT a.name
        FROM terms a
        JOIN user_interests b
        ON a.id = b.entity_id
        AND b.entity_type_class = 'Term'
        WHERE a.taxonomy = '#{taxonomy}'
        AND b.user_id = #{user.id})").collect {|dbr| dbr['id'].to_i}
  end

  def specific_entity_type_class
    case self.entity_type_class
    when "Term"
      self.real_item.taxonomy
    else
      self.entity_type_class
    end
  end

  def specified_interest_is_valid
    begin
      self.real_item
    rescue ActiveRecord::RecordNotFound
      self.errors.add(:entity_id, "El interés especificado no existe")
    end
  end

  def populate_menu_shortcut
    return if self.menu_shortcut.to_s != ""

    begin
      o = self.real_item
    rescue ActiveRecord::RecordNotFound
      # The validation code will prevent the interest from being saved in an
      # invalid state.
      return
    end

    case self.entity_type_class
    when "Term"
      self.menu_shortcut = o.slug
    else
      raise "Don't know what's the name of a #{o.class.name}"
    end
    true
  end

  def entity_name
    o = self.real_item
    case self.entity_type_class
    when "Portal"
      o.name

    when "Term"
      o.name

    else
      raise "Don't know what's the name of a #{o.class.name}"
    end
  end

  def real_item
    Object.const_get(entity_type_class).find(self.entity_id)
  end
end
