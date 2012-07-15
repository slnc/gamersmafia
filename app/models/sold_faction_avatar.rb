# -*- encoding : utf-8 -*-
class SoldFactionAvatar < SoldProduct
  #after_create :create_avatar

  def _use(options)
    if options[:level] == ''
      self.errors.add(:level, 'no has especificado un nivel de karma')
      return false
    end

    options[:level] = options[:level].to_i

    if options[:level] < 0 || options[:level] > 200
      self.errors.add(:level, 'el nivel de karma debe estar entre 0 y 200')
      return false
    end
    a = Avatar.new({:name => "f_#{self.user.faction_id}_#{Time.now.to_i}", :faction_id => self.user.faction_id, :submitter_user_id => self.user_id, :path => options[:path], :level => options[:level]})
    if a.save
      true #self.used = true # lo "consumimos" al crearlo porque se crea ya un avatar de usuario específico
      #self.save
    else
      self.errors.add(:file, a.errors.full_messages_html)
      false
    end
  end
end
