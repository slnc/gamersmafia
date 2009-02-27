class Topic < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable

  has_one :last_updated_item, :class_name => 'Topic'
  after_create :update_avg_popularity
  before_save :check_state

  validates_presence_of :topics_category, :message => 'El campo foro no puede estar en blanco'
  validates_presence_of :title, :message => 'El campo título no puede estar en blanco'
  validates_presence_of :main, :message => 'El campo texto no puede estar en blanco'

  def check_state
    self.state = Cms::PUBLISHED if self.state < Cms::PUBLISHED
  end

  def update_avg_popularity
    # TODO tb liimpiamos cache de avg_popularity de foro, pero aquí es mal lugar
    # TODO duplicado
    c = self.main_category
    c.avg_popularity = nil
    raise Exception unless c.save
  end

  after_create :update_forum_mod_time

  def update_forum_mod_time
    # TODO actualizar portada de foros
    # revisar cómo se actualizan los comments_count y posts_count al modificar topics/borrar, etc
    p = self.topics_category
    while p
      p.topics_count += 1 # no usamos :counter_cache por los estados
      p.last_topic_id = self.id
      p.last_updated_item_id = self.unique_content.id
      p.save # tb actualizamos updated_on
      p = p.parent
    end
  end

  def lastseen_on=(lastseen_on)
    @lastseen_on = lastseen_on
  end

  def update_counters_destroy
    p = self.topics_category
    while p
      TopicsCategory.decrement_counter('topics_count', p.id)
      p = p.parent
    end
  end

  def move_to_forum(new_forum)
    # TODO bug actualizar contadores de topics de foros afectados
    self.topics_category = new_forum
    self.topics_category_id = new_forum.id
    self.class.db_query("UPDATE #{Inflector::tableize(self.class.name)} SET topics_category_id = #{new_forum.id} WHERE id = #{self.id}")
  end
  
  def hot?
    # TODO
    # un topic es hot si su ratio de respuestas es mayor a la media de ese foro
    f = self.topics_category
    if f.avg_popularity.nil? then
      f.calculate_popularity
    end

    if self.updated_on.to_i > Time.now.to_i - 86400 * 30 and self.cache_comments_count.to_f / (Time.now.to_i - self.created_on.to_i) > f.avg_popularity.to_f then
      true
    else
      false
    end
  end
  
  def self.latest_by_category(limit=20)
    contents_r_root_id = {}
    i = 0
    Content.find_by_sql("SELECT contents.* 
                           FROM contents 
                          WHERE state = #{Cms::PUBLISHED}
                            AND clan_id IS NULL
                            AND id IN (SELECT last_updated_item_id 
                                         FROM terms 
                                        WHERE root_id = parent_id 
                                          AND taxonomy = 'TopicsCategory' 
                                          AND updated_on >= now() - '1 week'::interval)
                       ORDER BY updated_on DESC").each do |content|
      break if i >= limit
      next if contents_r_root_id.values.include?(content.real_content.id)
      root_term = content.terms.find(:all, :conditions => 'taxonomy = \'TopicsCategory\'')[0]
      contents_r_root_id[root_term.id] ||= content.real_content.id
      i += 1
    end
    contents_r_root_id.values
  end
end
