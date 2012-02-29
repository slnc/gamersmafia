module HasHid
  def self.included(base)
    base.extend AddHasMethod
  end

  module AddHasMethod
    def has_hid(hid_attr=nil)
      before_save "check_hid('#{hid_attr}')"

      class_eval <<-END
        include HasHid::InstanceMethods
      END
    end
  end

  module InstanceMethods
    def check_hid(mattr)
      if self.hid.to_s.strip == '' then
        base_hid = mattr.to_s == '' ? self.resolve_hid.to_s.bare : self[mattr.to_sym].to_s.bare
        base_hid.gsub!('_', '-')
        base_hid.gsub!('.', '')
        while base_hid =~ /--/
          base_hid.gsub!('--', '-')
        end
        base_hid.gsub!(/(-)$/, '')
        base_hid.gsub!(/^(-)/, '')
        # chequeamos que el hid sea único
        if self.class.base_class.count(:conditions => "hid = \'#{base_hid}\'") > 0 then
          incrementor = 1
          while self.class.base_class.count(:conditions => "hid = \'#{base_hid}_#{incrementor}\'") > 0
            incrementor += 1
          end
          self.hid = "#{base_hid}_#{incrementor}"
        else
          self.hid = "#{base_hid}"
        end
      end
      true
    end
  end
end

ActiveRecord::Base.send :include, HasHid
