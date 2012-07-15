# -*- encoding : utf-8 -*-
class SoldCommentsSig < SoldProduct
  after_create :update_user

  def update_user
    u = self.user
    u.enable_comments_sig = true
    u.comment_show_sigs = true
    u.save
    self.used = true # lo "consumimos" al crearlo porque se crea ya un avatar de usuario específico
    self.save
  end
end
