class SoldRadar < SoldProduct
  after_create :update_user

  def update_user
    self.user.pref_radar_notifications = "1"
    self.update_attribute(:used, true)
  end
end
