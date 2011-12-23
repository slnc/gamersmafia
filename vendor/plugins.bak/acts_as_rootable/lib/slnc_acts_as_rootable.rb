# Añade hooks al modelo para que cuando cambie el parent_id se sincronice
# correctamente el root_id de la categoría
module SlncActsAsRootable
  def self.included(base)
    base.extend AddActsAsMethod
  end

  module AddActsAsMethod
    def acts_as_rootable
      observe_attr :parent_id
      observe_attr :root_id
      before_save :check_parent_id
      after_create :check_parent_id_on_create

      class_eval <<-END
        include SlncActsAsRootable::InstanceMethods
      END
    end
  end

  module InstanceMethods
    protected
    def check_parent_id_on_create
      self.check_parent_id
      self.save
    end

    def check_parent_id
      if self.new_record? or self.slnc_changed?(:parent_id) or self.root_id.nil?
        if self.parent_id
          p = self.parent
          while p.parent_id
            p = p.parent
          end

          self.root_id = p.id
        else
          self.root_id = self.id
        end
      end
    end
  end
end
