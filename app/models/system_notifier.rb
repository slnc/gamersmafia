require 'pathname'
class SystemNotifier < ActionMailer::Base
  SYSTEM_EMAIL_ADDRESS = %{"GM Error Notifier" <httpd@gamersmafia.com>}
  SYSTEM_EMAIL_ADDRESS_CRITICAL = %{"GM Critical Condition" <httpd@gamersmafia.com>}
  EXCEPTION_RECIPIENTS = %w{rails-gm@slnc.net}

  def exception_notification(controller, request,
                             exception, sent_on=Time.now)
    @subject = sprintf("[ERROR] %s\#%s (%s) %s",
    controller.controller_name,
    controller.action_name,
    exception.class,
    exception.message.inspect)
    @body = { "controller" => controller, "request" => request,
    "exception" => exception,
    "backtrace" => sanitize_backtrace(exception.backtrace),
    "host" => request.env["HTTP_HOST"],
    "rails_root" => rails_root }
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENTS
    @headers = {}
  end

  def notification404_notification(uri, referer, request)
    sent_on=Time.now
    @subject = sprintf("[404] #{uri}#{referer}".tob64u)
    @body = { :uri => uri, :referer => referer, :request => request}
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENTS
    @headers = {}
  end

  def support_db_oos(prod, support)
    sent_on=Time.now
    @subject = "Support DB Out Of Sync"
    @body = { :prod => prod, :support => support}
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS_CRITICAL
    @recipients = EXCEPTION_RECIPIENTS
    @headers = {}
  end

  private
  def sanitize_backtrace(trace)
    re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
    trace.map do |line|
      Pathname.new(line.gsub(re, "[Rails.root]")).cleanpath.to_s
    end
  end

  def rails_root
    @rails_root ||= Pathname.new(Rails.root).cleanpath.to_s
  end
end
