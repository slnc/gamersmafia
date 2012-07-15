# -*- encoding : utf-8 -*-
class SoldUserAvatar < SoldProduct
  after_create :create_avatar

  def create_avatar
    Avatar.create({:name => "u_#{self.user_id}_#{self.user.avatars.count + 1}", :user_id => self.user_id, :submitter_user_id => self.user_id})
    self.used = true # lo "consumimos" al crearlo porque se crea ya un avatar de usuario específico
    self.save
  end
end
