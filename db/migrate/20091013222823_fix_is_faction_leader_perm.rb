class FixIsFactionLeaderPerm < ActiveRecord::Migration
  def self.up
    User.find(:all, :conditions => 'is_faction_leader = \'t\'').each do |u|
      u.check_is_staff
    end
  end

  def self.down
  end
end
