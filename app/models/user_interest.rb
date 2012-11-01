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
         AND created_on >= NOW() - '3 months'::interval) AS total_recent_contents
      FROM contents_terms
      WHERE content_id IN (
        SELECT content_id
        FROM tracker_items
        WHERE user_id = #{user.id})").each do |dbr|
      term_id = dbr['term_id'].to_i
      if !term_frequencies.include?(term_id)
        term_totals[term_id] = dbr['total_recent_contents'].to_i
        term_frequencies[term_id] = 0
      end
      term_frequencies[term_id] += 1
    end
    threshold = 0.7
    puts "user_id term_id frequency likelihood_visit"
    term_frequencies.each do |term_id, frequency|
      likelihood_visit = frequency.to_f / term_totals[term_id]
      puts "#{user.id}\t#{term_id}\t#{frequency}\t#{likelihood_visit}"
      if likelihood_visit  >= threshold
        user.user_interests.create(
            :entity_type_class => "Term", :entity_id => term_id)
      end
    end
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
