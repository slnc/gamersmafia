# -*- encoding : utf-8 -*-
class UserInterest < ActiveRecord::Base
  VALID_ENTITY_CLASSES = %w(
    Term
  )
  validates_uniqueness_of :entity_id, :scope => [:user_id, :entity_type_class]

  scope :interest_tuple,
    lambda { |entity_type_class, entity_id|
                 {
                   :conditions => ["entity_type_class = ? AND entity_id = ?",
                                   entity_type_class, entity_id]
                 }
  }

  belongs_to :user

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

  def entity_name
    o = Object.const_get(entity_type_class).find(self.entity_id)
    case self.entity_type_class
    when "Term"
      o.name
    else
      raise "Don't know what's the name of a #{o.class.name}"
    end
  end
end
