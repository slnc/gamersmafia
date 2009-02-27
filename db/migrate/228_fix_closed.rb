class FixClosed < ActiveRecord::Migration
  def self.up
    ContentType.find(:all, :order => 'lower(name)').each do |ct|
      puts ct.name
      Object.const_get(ct.name).find(:all, :conditions => 'closed = \'t\'').each do |rcont|
        User.db_query("UPDATE contents SET closed = 't' WHERE id = #{rcont.unique_content_id}")
      end
    end
  end
  
  def self.down
  end
end
