# puts ActiveSupport::Inflector.pluralize('hola')
# Este módulo se encarga de añadir funcionalidad de categoría a los objetos que
# se puedan clasificar
module ActsAsCategorizable
  def self.included(base)
    base.extend AddActsAsCategorizable
  end
  
  module AddActsAsCategorizable
    def acts_as_categorizable
      # creamos la clase Category
      klass = Class.new(ActiveRecord::Base) do
        protected
        # Returns the class type of the record using the current module as a prefix. So descendents of
        # MyApp::Business::Account would appear as MyApp::Business::AccountSubclass.
        def self.compute_type(type_name)
          modularized_name = type_name_with_module(type_name)
          begin
            instance_eval(modularized_name)
          rescue NameError => e
            instance_eval(type_name)
          rescue SyntaxError => e # necestario para nuestras clases, es el único cambio
            instance_eval(self.name)
          end
        end
      end
      
      # nota: el orden IMPORTA
      Object.const_set("#{Inflector::pluralize(self.name)}Category", klass)
      klass.set_table_name("#{Inflector::tableize(self.name)}_categories")
      klass.act_as_category
      # raise "#{Inflector::tableize(self.name)}_category"
      belongs_to "#{Inflector::tableize(self.name)}_category".to_sym
      observe_attr "#{Inflector::tableize(self.name)}_category_id".to_sym
      validates_presence_of "#{Inflector::tableize(self.name)}_category", :message => "El campo categoría no puede estar en blanco"
      
      class_eval <<-END
        include ActsAsCategorizable::InstanceMethods
      END
      
      before_save :update_category_totals
      
      #      after_save :update_category_totals
      #      
      
    end
  end
  
  module InstanceMethods
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def is_categorizable?
        true
      end
      
      def category_class # helper class to get access to this content's category
        Object.const_get("#{Inflector::pluralize(self.name)}Category")
      end
      
      def category_attrib_name
        "#{Inflector::tableize(self.name)}_category_id".to_sym
      end
    end
    
    def update_category_totals
      if self.slnc_changed?(self.class.category_attrib_name) && self.state == Cms::PUBLISHED
        prev = self.slnc_changed_old_values[self.class.category_attrib_name]
        if prev then
          prev = self.class.category_class.find(prev)
           (prev.get_ancestors + [prev]).each do |anc|
            anc.class.decrement_counter("#{Inflector::tableize(self.class.name)}_count", anc.id)
          end
        end
        
        
         (self.main_category.get_ancestors + [self.main_category]).each do |anc|
          anc.class.increment_counter("#{Inflector::tableize(self.class.name)}_count", anc.id)
        end
      elsif self.slnc_changed?(:state) && self.state == Cms::DELETED
       (self.main_category.get_ancestors + [self.main_category]).each do |anc|
          anc.class.decrement_counter("#{Inflector::tableize(self.class.name)}_count", anc.id)
        end
      end
    end
    
    def is_categorizable?
      true
    end
  end
  
end

ActiveRecord::Base.send(:include, ActsAsCategorizable)
