# puts ActiveSupport::ActiveSupport::Inflector.pluralize('hola')
# Este módulo se encarga de añadir funcionalidad de categoría a los objetos que
# se puedan clasificar
module ActsAsCategorizable
  def self.included(base)
    base.extend AddActsAsCategorizable
  end

  module AddActsAsCategorizable
    def acts_as_categorizable
      class_eval <<-END
        include ActsAsCategorizable::InstanceMethods
      END

      before_save :update_category_totals
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
    end

    def update_category_totals
      self.main_category.recalculate_counters if self.main_category
    end

    def is_categorizable?
      true
    end
  end
end

ActiveRecord::Base.send(:include, ActsAsCategorizable)
