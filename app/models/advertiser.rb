# -*- encoding : utf-8 -*-
class Advertiser < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :due_on_day # primer día del mes que no está pagado. Los informes se enviarán a las 00:05 de este día del mes cada mes
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[A-Za-z]{2,})$/
  has_many :ads

  has_users_skill 'Advertiser'

  def self.send_reports_to_publisher_if_on_due_date
    # This scripts executes on the first day of the non paid period so we return
    # the info ending yesterday midnight.
    tend = Time.now.at_beginning_of_day.ago(1)
    tstart = tend.months_ago(1).beginning_of_day
    Advertiser.find(
        :all,
        :conditions => ["active='t' AND due_on_day = ?", Time.now.day]
    ).each do |advertiser|
      NotificationEmail.ad_report(
          advertiser, {:tstart => tstart, :tend => tend}).deliver
    end
  end

end
