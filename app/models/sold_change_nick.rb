# -*- encoding : utf-8 -*-
class SoldChangeNick < SoldProduct
  def _use(options)
    if User::OLD_LOGIN_REGEXP =~ options[:nuevo_login]
      old_login = self.user.login
      self.user.login = options[:nuevo_login]
      if self.user.save
        UserLoginChange.create(:user_id => self.user_id, :old_login => old_login)
        true
      else
        false
      end
    else
      self.errors.add("nuevo nick", User::INVALID_LOGIN_CHARS)
      false
    end
  end
end
