class RecreateMissingBazarCtegories < ActiveRecord::Migration
  def self.up
    # cats es un array de instancias de las clases de bazar de primer nivel
TutorialsCategory.create(:name => 'Bazar', :code => 'bazar') 
    cats = [TopicsCategory.find_by_code('bazar'),  NewsCategory.find_by_code('bazar'), ImagesCategory.find_by_code('bazar'), TutorialsCategory.find_by_code('bazar')]   
    cats.each do |cat|
      [['Anime', 'anime'],  
      ['Cine y SeriesTV', 'cine'],
      ['Deportes', 'deportes'],
      ['Desarrollo', 'desarrollo'],
      ['Hardware', 'hw'],
      ['Informatica', 'informatica'],
      ['Internet', 'inet'],
      ['Musica', 'musica'],
      ['Vida Estudiante', 'estudiante']].each do |blck|
        name, code = blck[0], blck[1]
        if cat.children.find(:first, :conditions => ['parent_id = ? AND code = ? AND name = ?', cat.id, code, name]).nil?
          puts "creating #{cat.class.name} category #{name} (#{code})"
          cat.children.create(:name => name, :code => code)
        end
      end
    
      vcats = ["'anime'", "'cine'", "'deportes'", "'desarrollo'", "'hw'", "'informatica'", "'inet'", "'musica'", "'estudiante'"]      
      inet = TopicsCategory.find_by_code('inet')
      cat.children.find(:all, 
                        :conditions => "code is null 
                                     or code not in (#{vcats.join(',')})").each do |icat|
        puts "moviendo cat #{icat.name} (#{icat.code})"
        User.db_query("UPDATE topics_categories SET parent_id = #{inet.id}, root_id = #{inet.id} WHERE id = #{icat.id}")
        icat.parent_id = inet.id
        icat.root_id = inet.id
        icat.save
      end
    end
    
    
    # TODO hacer algo con el resto de categorías
    puts "Tildes de categorias informatica y musica!!"
  end
  
  def self.down
  end
end
