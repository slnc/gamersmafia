class FixCompetitionsMatchesWebsite < ActiveRecord::Migration
  def self.up
    Event.find(:all, :conditions => 'website LIKE \'http:///%\'').each do |ev|
      ev.website = "http://#{App.domain_arena}/#{ev.website.gsub('http://', '')}"
    end
  end

  def self.down
  end
end
