class FixCompetitionsRoles < ActiveRecord::Migration
  def self.up
    Competition.find(:all, :order => 'lower(name)').each do |c|
      puts c.name
      c.adminsDEPRECATED.each do |u|
        c.add_admin(u)
      end
      
      c.supervisorsDEPRECATED.each do |u|
        c.add_supervisor(u)
      end
    end
  end

  def self.down
  end
end
