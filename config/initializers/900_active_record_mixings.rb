# -*- encoding : utf-8 -*-
module ActiveRecordMixings

  def self.included(base)
    base.extend ClassMethods
  end

  def db_query(q)
    self.class.db_query(q)
  end

  def changed_attr(field_name)
    self.changed.include?(field_name)
  end
  alias :changed_attr? :changed_attr

  def changed_attr_before_save(field_name)
    self.previous_changes.include?(field_name)
  end
  alias :changed_attr_before_save? :changed_attr_before_save

  def update_without_timestamping
    class << self
      def record_timestamps; false; end
    end

    if !save
     raise "Error al guardar #{self.class.name}(#{self.id}): #{self.errors.full_messages_html}"
    end

    class << self
      def record_timestamps; super ; end
    end
  end

  define_method 'delete_associated_users_skills' do
    return true unless self.id
    instance_eval <<-END
    self.class._users_skills.each do |urname|
      UsersSkill.find(:all, :conditions => ['role = ? AND role_data = ?', urname, self.id.to_s]).each do |ur|
        ur.destroy
      end
    end
    END
    true
  end

  module ClassMethods
    def paginate_in_reverse(options = {})
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

    def has_users_skill(role_name)
      class_eval <<-END

      @@_users_skills ||= []
      @@_users_skills << role_name
      cattr_accessor :_users_skills
      END
      before_destroy :delete_associated_users_skills
    end


    def observe_attr(*args)
      if args.size == 1 && !args.kind_of?(Array)
        args = [args]
      end
    end

    def find_or_404(*args)
      begin
        out = self.find(*args)
      rescue ActiveRecord::StatementInvalid => errstr
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

class ActiveModel::Errors
  def full_messages_html
    out = '<ul>'
    self.each do |attr, msg|
      out = "#{out}<li><strong>#{ActiveSupport::Inflector::titleize(attr)}</strong> #{msg}</li>"
    end
    out = "#{out}</ul>"
  end
end

ActiveRecord::Base.send :include, ActiveRecordMixings
ActiveRecord::Base.partial_updates = false
