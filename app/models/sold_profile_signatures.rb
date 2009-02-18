class SoldProfileSignatures < SoldProduct
  after_create :update_user

  def update_user
    u = self.user
    u.enable_profile_signatures = true
    u.save
    self.used = true # lo "consumimos" al crearlo porque se crea ya un avatar de usuario específico
    self.save
  end
end
