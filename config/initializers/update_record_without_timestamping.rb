module ActiveRecord
  class Base
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

  end
end
