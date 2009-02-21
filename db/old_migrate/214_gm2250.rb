class Gm2250 < ActiveRecord::Migration
  def self.up
slonik_execute "alter table users add column is_staff bool not null default false;"
    Faction.find(:all, :conditions => 'boss_user_id IS NOT NULL or underboss_user_id IS NOT NULL', :order => 'lower(name)').each do |f|
      puts f.name
      f.update_boss(User.find(f.boss_user_id)) if f.boss_user_id
      f.update_underboss(User.find(f.underboss_user_id)) if f.underboss_user_id
    end
  end

  def self.down
  end
end
