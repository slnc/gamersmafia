class Event < ActiveRecord::Base
  acts_as_content
  acts_as_categorizable
  
  has_many :coverages
  
  has_and_belongs_to_many :users
  
  acts_as_tree :order => 'title'
  
  has_one :competition_match
  has_one :competition
  before_validation :check_website_format
  
  def check_website_format
    if self[:website] && self[:website].to_s.strip != '' && !(self[:website] =~ /^http:\/\//)
      self[:website] = 'http://' << self[:website]
    end
  end
  
  
  CURRENT_SQL = "events.starts_on < now() + '2 months'::interval
                     AND events.parent_id is null
                     AND events.ends_on > now() 
                     AND events.id not in (SELECT event_id from competitions)"
                     
  def self.current(opts={})
    opts = {:order => 'starts_on', :limit => 7}.merge(opts)
    conds = CURRENT_SQL
                     
    if opts[:conditions]
      opts[:conditions] << " AND #{conds}"
    else
      opts[:conditions] = conds
    end
    
    self.find(:published, opts)
  end
  
  # TODO esto falla ahora mismo para portales distintos de gm_portal
  def self.intersect_day(t)
    find(:all, 
         :conditions => "state = #{Cms::PUBLISHED}
                     AND id not in (SELECT event_id from competitions where event_id is not null) 
                     AND parent_id is null
                     AND date_trunc('day', to_timestamp('#{t.strftime('%Y%m%d%H%M%S')}', 'YYYYMMDDHH24MISS')) BETWEEN date_trunc('day', starts_on) AND date_trunc('day', ends_on)")
  end
  
  
  # Devueve un diccionario de días como claves del mes dado. Cada día tiene un
  # valor entre 0 y 3 que representa la actividad de dicho día en cuestión de
  # eventos.
  def self.hotmap(t, opts={})
    month_start = Time.local(t.year, t.month, 1, 0, 0, 0)
    if t.month + 1 > 12
      month_end = Time.at(Time.local(t.year + 1, 1, 1, 0, 0, 0).to_i - 1)
    else
      month_end = Time.at(Time.local(t.year, t.month + 1, 1, 0, 0, 0).to_i - 1)
    end
    
    hotmap = {}
    
    # buscamos todos los eventos en la intersección
    self.find(:published, 
             :conditions => "id not in (SELECT event_id from competitions where event_id is not null) 
                     AND parent_id is null
                     AND date_trunc('month', to_timestamp('#{t.strftime('%Y%m%d%H%M%S')}', 'YYYYMMDDHH24MISS')) BETWEEN date_trunc('month', starts_on) AND date_trunc('month', ends_on)").each do |e|
      
      start_d = Time.local(e.starts_on.year, e.starts_on.month, e.starts_on.day) # ponemos el primer día a 00:00:00 
      end_d = Time.local(e.ends_on.year, e.ends_on.month, e.ends_on.day, 23, 59, 59) # ponemos el último día a 23:59:59
      
      start_d = month_start if e.starts_on.to_i < month_start.to_i # usamos .to_i por las diff de ms entre pg y ruby
      end_d = month_end if e.ends_on.to_i > month_end.to_i
      
      cur_day = start_d.day
      
       (((end_d - start_d).to_i + 1) / 86400).times do |t|
        hotmap[cur_day] ||= 0
        hotmap[cur_day] += 1  # añadimos un evento al día en curso
        cur_day += 1
      end
    end
    
    # limito los outliers a 2 desviaciones standard
    a = [0]
    hotmap.each_value {|v| a<< v}
    if a.max > 3 then
      stddev = Math.standard_deviation(a)
      avg = Math.mean(a)
      max = avg + 2 * stddev
      min = avg - 2 * stddev
      
      hotmap2 = {}
      hotmap.each_pair do |k,v|
        if v > max
          hotmap2[k] = max
        elsif v < min
          hotmap2[k] = min
        else
          hotmap2[k] = v
        end
      end
      
      a_max = (max > a.max) ? a.max : max
      range3 = a_max * 3.0 / 4
      range2 = a_max * 2.0 / 4
      range1 = a_max * 1.0 / 4
      
      hotmap = {}
      hotmap2.each_pair { |k,v| 
        if v >= range3
          hotmap[k] = 3
        elsif v >= range2
          hotmap[k] = 2
        elsif v >= range1
          hotmap[k] = 1
        else
          hotmap[k] = 0
        end
      }
    end
    
    # limito los valores de los días
    hotmap
  end
  
  def member_join(u)
    self.users<< u
    self.save
  end
  
  def member_leave(u)
    self.users.delete(u)
    self.save
  end
  
  validates_format_of :website, :with => Cms::URL_REGEXP, :if => Proc.new{ |c| c.website.to_s != '' }
end
