class Poll < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable
  
  after_save :process_polls_options
  after_save :fix_solapping_polls
  has_many :polls_options, :dependent => :destroy
  
  
  def fix_solapping_polls
    return if self.main_category.nil?
    # automatically change publish date if it solaps with existing poll
    solapping = self.main_category.poll.find(:first, :conditions => ["contents.state = #{Cms::PUBLISHED} AND starts_on <= ? AND ends_on >= ? ", self.starts_on, self.starts_on])
    while solapping && solapping.id != self.id
      self.starts_on = Time.at(solapping.ends_on.to_i + 1)
      self.ends_on = self.starts_on.advance(:days => 7)
      solapping = self.main_category.poll.find(:first, :conditions => ["contents.state = #{Cms::PUBLISHED} AND starts_on <= ? AND ends_on >= ? ", self.starts_on, self.starts_on])
    end
  end
  
  CURRENT_SQL = 'starts_on <= now() and ends_on >= now()'
  
  validates_uniqueness_of :title, :message => 'Ya hay otra encuesta con el mismo título'
  
  def recalculate_polls_votes_count
    new_polls_votes_count = User.db_query("SELECT count(*) 
    FROM polls_votes 
    WHERE polls_option_id in (SELECT id 
                                FROM polls_options 
                               WHERE poll_id = #{self.id})")[0]['count'].to_i                               
    User.db_query("UPDATE polls SET polls_votes_count = #{new_polls_votes_count} WHERE id = #{self.id}")
  end
  
    
  def options_new=(opts_new)
    @_tmp_options_new = opts_new
    self.attributes.delete :options_new 
  end
  
  def options_delete=(opts_new)
    @_tmp_options_delete = opts_new
    self.attributes.delete :options_delete 
  end
  
  def options=(opts_new)
    @_tmp_options = opts_new
    self.attributes.delete :options 
  end
  
  def process_polls_options
    if @_tmp_options_new
      @_tmp_options_new.each { |s| self.polls_options.create({:name => s.strip}) unless s.strip == ''  }
      @_tmp_options_new = nil
    end
    
    if @_tmp_options_delete
      @_tmp_options_delete.each { |id| self.polls_options.find(id).destroy if self.polls_options.find_by_id(id) }
      @_tmp_options_delete = nil
    end
    
    if @_tmp_options
      @_tmp_options.keys.each do |id|
        option = self.polls_options.find_by_id(id.to_i)
        if option && option.name != @_tmp_options[id]
          option.name = @_tmp_options[id].strip
          option.save
        end
      end 
      @_tmp_options = nil
    end
    true
  end
  
  def before_save
    if starts_on >= ends_on
      self.errors.add('starts_on', "La fecha de comienzo debe ser anterior a la fecha de finalización #{starts_on} #{ends_on}")
      false
    elsif starts_on <= Time.now and state <= Cms::PENDING
      self.errors.add('starts_on', "La fecha de comienzo debe ser posterior a la fecha y hora actuales #{starts_on}")
      false
    else
      true
    end
  end

  
  def votes
    self.db_query("select sum(b.polls_votes_count) from polls a join polls_options b on a.id = b.poll_id where a.id = #{self.id} group by (a.id)")[0]['sum'].to_i
  end
  
  def user_voted(user)
    ids = [0]
    for p in self.polls_options.find(:all):
      ids << p.id
    end
    ids = ids.join(', ')
    
    return PollsVote.find(:first, :conditions => ["polls_option_id IN (#{ids}) and user_id = ?", user.id])
  end
  
  
  def vote(polls_option, remote_ip, user_id=nil)
    ids = []
    # si la encuesta no está publicada y además es la encuesta actual no
    # contabilizamos los votos
    
    if !(self.starts_on <= Time.now and self.ends_on >= Time.now and self.is_public?) then
      return
    end
    
    for p in self.polls_options.find(:all):
      ids << p.id
    end
    ids = ids.join(', ')
    
    if user_id:
      # si el usuario ya ha votado no le dejamos cambiar su voto
      existing_vote = PollsVote.find(:first, :conditions => ["polls_option_id IN (#{ids}) and user_id = ?", user_id])
      if not existing_vote
        pollsvote = polls_option.polls_votes.create({:polls_option_id => polls_option.id, :remote_ip => remote_ip, :user_id => user_id})
        pollsvote.save
      end
    else
      # si es usuario anónimo sólo contamos su voto si no encontramos un voto desde esa ip de hace menos de 5 minutos a esta encuesta
      if not PollsVote.find(:first, :conditions => ["polls_option_id IN (#{ids}) and remote_ip = ? and created_on > (now() - '5 minutes'::interval)::timestamp", remote_ip])
        pollsvote = polls_option.polls_votes.create({:polls_option_id => polls_option.id, :remote_ip => remote_ip, :user_id => user_id})
        pollsvote.save
      end
    end
  end
  
  def votes
    # TODO cache
    total = self.db_query("select count(a.id) from polls_votes a join polls_options b on a.polls_option_id = b.id and b.poll_id = #{self.id}")[0]['count'].to_i
     (total.nil? ? 0 : total)
  end
end
