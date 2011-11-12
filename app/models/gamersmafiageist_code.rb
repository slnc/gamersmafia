require 'base64'
require 'digest'

class GamersmafiageistCode < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :code
  validates_uniqueness_of :user_id, :scope => :survey_edition_date
  validates_presence_of :survey_edition_date

  before_create :generate_code

  def generate_code
    raise "Existing code found" unless self.code.nil?
    self.code = Base64.encode64(Digest::SHA1.digest("#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}/"))[0..8]
  end
end
