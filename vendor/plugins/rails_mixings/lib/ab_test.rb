class AbTest < ActiveRecord::Base
  serialize :metrics, Array
  serialize :cache_conversion_rates, Hash
  validates_presence_of :metrics
  validates_presence_of :treatments
  
  before_save :clear_cache_if_changed_parameters
  observe_attr :min_difference, :treatments, :metrics, :completed_on
  
  def running_time
    if self.completed_on then
      self.completed_on - self.created_on
    else
      Time.now - self.created_on
    end
  end
  
  def get_visitor_treatment_num(visitor_id, user_id=nil)
    # Para evitar los problemas con spiders para nuevos visitantes asignamos un tratamiento
    # pero aqui no guardamos nada, depende del usuario y de su hit a /site/x el que lo guarde
    if user_id # check previous treatment 
      dbu = User.db_query("SELECT treatment 
                           FROM treated_visitors 
                          WHERE ab_test_id = #{self.id} 
                            AND (user_id = #{user_id}
                             OR visitor_id = #{User.connection.quote(visitor_id.to_s)})
                       ORDER BY id")
    else
      dbu = User.db_query("SELECT treatment 
                           FROM treated_visitors 
                          WHERE ab_test_id = #{self.id} 
                            AND visitor_id = #{User.connection.quote(visitor_id.to_s)}")
    end
    
    if (dbu.size == 0) then
      [assign_visitor_to_treatment(visitor_id), true]
    else
      [dbu[0]['treatment'].to_i, false]
    end
  end
  
  # devuelve un treatment
  def assign_visitor_to_treatment(visitor_id)
    # TODO this is private
    destiny = Kernel.rand
    increment = 1.0 / (1 + treatments)
    part = increment
    treatment_num = 0 # control
    while part < destiny
      treatment_num += 1
      part += increment
    end
    
    treatment_num #
  end
  
  def conversion_rates(recalculate=true)
    if cache_conversion_rates.nil? && recalculate
      reset_observable_attrs_state
      self.cache_conversion_rates = begin
        all_rates = {}
        metrics.each do |metric|
          metric = metric.to_sym
          case metric
            when :goal
            all_rates[metric] = _conversion_rates_sgoal(:clickthrough)
            when :comments
            # TODO borrar usuarios con javascript deshabilitado, es decir, salen en treated_visitors y no en stats.pageviews
            all_rates[metric] = _conversion_rates_sgoal(:clickthrough) #_conversion_rates(nil, nil, 'comentarios', 'crear')
          else
            all_rates[metric] = _conversion_rates_sgoal(metric)
          end
        end
        all_rates
      end
      self.dirty = false
      save
      self.cache_expected_completion_date = nil
      expected_completion_date # force cache regen
    end
    cache_conversion_rates
  end
  
  
  def desired_sample_rate(rates)
    val = rates[0][:impressions] ? :impressions : :stddev
    if rates[0][val] == 0
      0
    else
      if val == :impressions
        # std error of a bernouilli distribution because this is a bernouilli
        std_error = Math.sqrt(rates[0][:rate].to_f*(1-rates[0][:rate]))
      else
        std_error = rates[0][:stddev] # / Math.sqrt(rates[0][:visitors].to_f)
      end
      # min_difference = 0.05
      crate = rates[0][:rate]
       ((4.0 * (treatments+1) * std_error) / (crate * min_difference).to_f)**2
    end
  end
  
  # determina el porcentaje de completado del experimento actual en base a todas las métricas elegidas
  # se devuelve el mayor tiempo para completarse si el test tiene varias métricas
  def experiment_completedness(recalculate=true)
    rates_metrics = conversion_rates(recalculate)
    max = nil
    return max unless rates_metrics
    
    rates_metrics.keys.each do |rm|
      rates = rates_metrics[rm]
      cur_treated = 0.0
      rates.each do |k,v|
        cur_treated += rates[k][:impressions] ? rates[k][:impressions] : rates[k][:treated_visitors] # rates[k][:treated_visitors]  
      end
      cur_estimated = cur_treated / desired_sample_rate(rates)
      max = cur_estimated if max.nil? || cur_estimated > max
    end
    max
  end
  
  
  
  #rates[t] = Stats::Goals.custom() # ...
  #rates[t] = Stats::Goals.clickthrough(:controller_from => 'canales',
  #:action_from => 'noticia',
  #:controller_to => 'canales',
  #:action_to => 'noticia')
  
  
  def _conversion_rates_sgoal(sgoal)
    # Procesamos los resultados devueltos por Stats::Goals unicamente para añadir ratios relativos
    rates = {}
     (treatments+1).times do |t|
      rates[t] = Stats::Goals.send(sgoal, :ab_test_treatment => [self, t])
    end
    
    control_rate = rates[0][:rate]
    
    treatments.times do |i|
      curi = i + 1
      if control_rate == 0 || rates[curi][:impressions] == 0
        rates[curi][:relative_rate] = 0.0 # control esta a 0 o no tenemos impresiones asi que no podemos medir nada
      elsif rates[curi][:conversions] == 0 # tenemos impresiones y no conversiones pero div0 asi que -100%
        rates[curi][:relative_rate] = -1.0
      else # podemos calcular el ratio relativo dividiendo
        base_rel = rates[curi][:rate] / control_rate
        if base_rel > 1.0
          rates[curi][:relative_rate] = base_rel - 1.0
        elsif base_rel == 1.0 # tenemos el mismo rate que  control
          rates[curi][:relative_rate] = 0.0
        else
          rates[curi][:relative_rate] = -(1.0 - base_rel)
        end
      end
    end
    rates
  end
  
  
  def expected_completion_date
    if cache_expected_completion_date.nil?
      # tiempo que hemos tardado en conseguir las impresiones actuales
      self.cache_expected_completion_date = begin
        if completed_on then
          self.completed_on
        else
          secs_done = Time.now.to_i - self.created_on.to_i
          secs_total = secs_done / ((experiment_completedness > 0) ? experiment_completedness : 1.0) 
           (secs_total - secs_done).seconds.since
        end
      end
      
      self.save
    end
    self.cache_expected_completion_date
  end
  
  def get_assigned_visitors_rates
    rates = {}
    User.db_query("SELECT treatment, count(*) FROM treated_visitors WHERE ab_test_id = #{self.id} GROUP BY treatment ORDER BY treatment").each do |dbr|
      rates[dbr['treatment'].to_i] = dbr['count'].to_i
    end
    rates
  end
  
  def end_experiment
    return false if completed_on
    self.completed_on = Time.now
    self.save
  end
  
  def best_treatment(metric)
    # returns best treatment and it's data
    binfo = {:type => nil, :value => nil, :relative_improvement => nil}
    metric = metric.to_sym
     (self.treatments+1).times do |treatment|
      next if conversion_rates[metric][treatment].nil? || conversion_rates[metric][treatment][:treated_visitors] == 0
      
      cur_rate = conversion_rates[metric][treatment][:rate]
      if binfo[:value].nil? || cur_rate > binfo[:value]
        binfo[:abbrv] = Stats::Goals.available_goals_abbrv[metric]
        binfo[:type] = binfo[:value].nil? ? 'C' : "T#{treatment}"
        binfo[:value] = cur_rate
        relmetric = conversion_rates[metric][treatment][:rate] / conversion_rates[metric][0][:rate]
        binfo[:relative_improvement] = (relmetric > 1.0 ? (relmetric-1.0) : -1.0 +relmetric)*100
      end
    end
    
    binfo
  end
  
  private
  def clear_cache_if_changed_parameters
    if slnc_changed?(:min_difference) || slnc_changed?(:treatments) || slnc_changed?(:metrics) || slnc_changed?(:completed_on)
      self.dirty = true
    end
  end
  
  def self.update_ab_tests
    AbTest.find(:all, :conditions => "created_on > now() - '1 day'::interval AND active = \'t\' AND (dirty = \'t\' or completed_on is null)").each do |abt|
      # puts "refreshing young test #{abt.name}"
      abt.cache_conversion_rates = nil
      abt.conversion_rates
    end

    # los tests con más de 1 día de antigüedad los refrescamos solo una vez al día
    AbTest.find(:all, :conditions => "created_on < now() - '1 day'::interval AND updated_on  < now() - '1 day'::interval  AND active = \'t\' AND (dirty = \'t\' or completed_on is null)").each do |abt|
      # puts "refreshing old test #{abt.name}"
      abt.cache_conversion_rates = nil
      abt.conversion_rates
    end
  end
end
