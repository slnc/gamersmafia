# -*- encoding : utf-8 -*-
# Necesario para especificar Return-Path.
class ActionMailer::Base
  def perform_delivery_sendmail(mail)
    @return_path = App.system_mail_user if @return_path.nil?
    location = sendmail_settings[:location]
    arguments = sendmail_settings[:arguments]

    IO.popen("#{location} -f #{mail.from} -r #{@return_path} #{arguments}",
             "w+") do |sm|
      sm.print(mail.encoded.gsub(/\r/, ''))
      sm.flush
    end
  end
end
