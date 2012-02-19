module ActiveRecordMixings
  def self.included(base)
    base.extend ClassMethods
  end
  
  def db_query(q)
    self.class.db_query(q)
  end
  
  def reset_observable_attrs_state
    @slnc_changed = nil
  end
  
  def slnc_changed?(attr_name = nil)
    attr_name ? (@slnc_changed && @slnc_changed[attr_name]) : (@slnc_changed && @slnc_changed.any?)
  end
  
  define_method 'delete_associated_users_roles' do
    return true unless self.id
    instance_eval <<-END
    self.class._users_roles.each do |urname|
      UsersRole.find(:all, :conditions => ['role = ? AND role_data = ?', urname, self.id.to_s]).each do |ur|
        ur.destroy
      end
    end
    END
    true
  end
  
  module ClassMethods
    def has_users_role(role_name)
      class_eval <<-END
      
      @@_users_roles ||= []
      @@_users_roles << role_name
      cattr_accessor :_users_roles
      END
      before_destroy :delete_associated_users_roles
    end
    
    def observe_attr(*args)
      if args.size == 1 && !args.kind_of?(Array)
        args = [args]
      end
      # args = [args] unless args.kind_of?(Array)
      attr_accessor :slnc_changed, :slnc_changed_old_values
      args.each do |attr_name|
        begin
          alias_method("old_#{attr_name}=".to_sym, "#{attr_name}=".to_sym) if self.new.respond_to?("#{attr_name}=")
        rescue: # ignoramos todos en lugar de solo NameError porque en acts_as_rootable no existe la tabla a la hora de leer la clase
        end
        
        define_method "#{attr_name}=" do |value|
          @slnc_changed ||= HashWithIndifferentAccess.new
          @slnc_changed_old_values ||= HashWithIndifferentAccess.new
          @slnc_changed_old_values[attr_name] = self.send attr_name.to_sym
          if self.respond_to?("old_#{attr_name}=")
            send("old_#{attr_name}=", value) 
          else
            write_attribute attr_name, value
          end
          @slnc_changed[attr_name] = true if self.send(attr_name.to_sym) != @slnc_changed_old_values[attr_name] # hacemos esta comprobación por file_column
        end
      end
    end
    
    def find_or_404(*args)
      begin
        out = self.find(*args)
      rescue ActiveRecord::StatementInvalid => errstr:
        # si el error es por meter mal el id cambiamos la excepción a recordnotfound
        raise ActiveRecord::RecordNotFound if not errstr.to_s.index('invalid input syntax for integer').nil?
      end
      
      raise ActiveRecord::RecordNotFound if out.nil? 
      
      out
    end
    
    def db_query(q)
      return self.connection.select_all(q)
    end
    
    def plain_text(*args)
      before_save :sanitize_plain_text_fields # unless @@plain_text_fields.size > 0
      args = [args.first] if args.kind_of?(String)
      # Necesario que vaya en class_eval por las referencias a @@
      
      class_eval <<-END
          @@plain_text_fields ||= []
          @@plain_text_fields += args

          # TODO esto hará redefinir la función

          def sanitize_plain_text_fields
            @@plain_text_fields.each do |field| 
              self[field.to_s] = self[field.to_s].to_s.gsub('<', '&lt;')
              self[field.to_s] = self[field.to_s].to_s.gsub('>', '&gt;')
            end
          end
        END
    end
    
    # sirve para validar logins y emails
    def validates_uniqueness_ignoring_case_of(*attr_names)
      configuration = { :message => 'duplicated' }
      configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
      validates_each attr_names do |m, a, v| 
        if m.new_record?
          m.errors.add(a, configuration[:message]) if not User.find(:first, :conditions => ["lower(#{a}) = lower(?)", v]).nil?
        else
          m.errors.add(a, configuration[:message]) if not User.find(:first, :conditions => ["id <> ? and lower(#{a}) = lower(?)", m.id, v]).nil?
        end
      end
    end
  end
end

class ActiveRecord::Errors
  def full_messages_html
    out = '<ul>'
    self.each do |attr, msg|
      out = "#{out}<li><strong>#{ActiveSupport::Inflector::titleize(attr)}</strong> #{msg}</li>"
    end
    out = "#{out}</ul>"
  end
end

if RAILS_GEM_VERSION == '2.1.2'
  module ::ActiveRecord
    module QueryCache
      alias :cache :uncached
    end
  end
end

class ActiveRecord::Migration
  def self.slonik_execute(str)
    if App.enable_slonik?
      set_id = User.db_query("select tab_set from _#{REPLICATION_CLUSTER}.sl_table group by tab_set order by count(*) desc limit 1")[0]['tab_set']
      raise "set_id not found" unless set_id != ''
      puts `/usr/local/hosting/bin/slonik_execute_script -C "#{str}" set#{set_id} | /usr/local/hosting/bin/slonik` 
    else
      User.db_query(str)
    end    
  end
end

ActiveRecord::Base.class_eval do
  def self.paginate_in_reverse(options = {})
    unless options[:page]
      # we only default to the last page if no explicit page has been given
      total_entries = self.count(:conditions => options[:conditions])
      # calculate the last page
      per_page = options[:per_page] ? options[:per_page] : self.per_page
      total_pages = (total_entries / per_page.to_f).ceil
      # update the options hash to hold this information
      options = options.merge(:page => total_pages, :total_entries => total_entries)
    end
    
    # do the usual stuff
    self.paginate(options)
  end
end
