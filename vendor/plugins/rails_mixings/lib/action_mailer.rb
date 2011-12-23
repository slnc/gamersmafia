# necesario para que el Return-Path se ponga bien.
class ActionMailer::Base
  def perform_delivery_sendmail(mail)
    @return_path = App.system_mail_user if @return_path.nil?
    IO.popen("#{sendmail_settings[:location]} -f #{mail.from} -r #{@return_path} #{sendmail_settings[:arguments]}","w+") do |sm|
      sm.print(mail.encoded.gsub(/\r/, ''))
      sm.flush
    end
  end
end
