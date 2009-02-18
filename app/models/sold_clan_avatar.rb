class SoldClanAvatar < SoldProduct
  #  after_create :create_avatar
  #
  #  def create_avatar
  #    Avatar.create({:name => "c_#{self.clan_id}_#{self.clan.avatars.count + 1}", :clan_id => self.clan_id, :submitter_user_id => self.user_id})
  #    self.used = true # lo "consumimos" al crearlo porque se crea ya un avatar de clan específico
  #    self.save
  #  end
  def _use(options)
    clan = Clan.find(options[:clan_id])
    raise AccessDenied unless clan.user_is_member(self.user_id)
    Avatar.create({:name => "c_#{clan.id}_#{clan.avatars.count + 1}", :clan_id => clan.id, :submitter_user_id => self.user_id, :path => options[:path]})
    true
  end
end
