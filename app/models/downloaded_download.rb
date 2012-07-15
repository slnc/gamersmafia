# -*- encoding : utf-8 -*-
class DownloadedDownload < ActiveRecord::Base
  belongs_to :download
  belongs_to :user

  before_create :set_download_cookie

  #validates_presence_of :session_id
  validates_presence_of :ip

  def set_download_cookie
    self.download_cookie = Digest::MD5.hexdigest("#{Time.now.to_i}.#{session_id}.#{self.ip}.#{self.download_id}")
    true
  end
end
