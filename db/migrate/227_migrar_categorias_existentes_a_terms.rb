class MigrarCategoriasExistentesATerms < ActiveRecord::Migration
  def self.up
    i = 0
    (Cms.contents_classes + [Blogentry]).each do |cls|
      puts cls.name
      cls.find(:all, :conditions => 'unique_content_id IS NULL').each do |rc|
        User.db_query("UPDATE #{Inflector::tableize(rc.class.name)} SET unique_content_id = #{rc.OLD_unique_content.id} WHERE id = #{rc.id}")
        i += 1
      end
      puts "#{i} procesados"
    end
  end
  
  def self.down
  end
end
