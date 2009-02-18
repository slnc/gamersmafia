class ResetUrlsOfRecentContents < ActiveRecord::Migration
  def self.up
    execute "update contents set url = NULL where created_on > now() - '2 weeks'::interval;"
  end

  def self.down 
  end
end
