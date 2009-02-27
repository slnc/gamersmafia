class AddClosedToOtherContents < ActiveRecord::Migration
  def self.up
    ContentType.find(:all, :conditions => 'name <> \'Topic\'').each do |ct|
      slonik_execute "alter table #{Inflector::tableize(ct.name)} add column closed bool not null default false;"
    end
    
    #ContentType.find(:all, :conditions => 'name <> \'Topic\'').each do |ct|
      #puts "alter table "<< Inflector::tableize(ct.name) << " add column closed bool not null default false;"
    #end
  end

  def self.down
  end
end
