module HasSlug
  def self.included(base)
    base.extend AddHasMethod
  end

  module AddHasMethod
    def has_slug(slug_attr=nil)
      before_save "check_slug('#{slug_attr}')"

      class_eval <<-END
        include HasSlug::InstanceMethods
      END
    end
  end

  module InstanceMethods
    def check_slug(mattr)
      if self.slug.to_s.strip == '' then
        base_slug = mattr.to_s == '' ? self.resolve_slug.to_s.bare : self[mattr.to_sym].to_s.bare
        base_slug.gsub!('_', '-')
        base_slug.gsub!('.', '')
        while base_slug =~ /--/
          base_slug.gsub!('--', '-')
        end
        base_slug.gsub!(/([_-]+)$/, '')
        base_slug.gsub!(/^(-)/, '')
        # chequeamos que el slug sea único
        if self.class.find(:first, :conditions => "slug = \'#{base_slug}\'") then
          incrementor = 1
          while self.class.find(:first, :conditions => "slug = \'#{base_slug}_#{incrementor}\'")
            incrementor += 1
          end
          self.slug = "#{base_slug}_#{incrementor}"
        else
          self.slug = "#{base_slug}"
        end
      end
      true
    end
  end
end
