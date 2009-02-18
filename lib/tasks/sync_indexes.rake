namespace :gm do
  desc "Sync indexes"
  task :sync_indexes => :environment do
    Rake::Task["gm:sync_indexes:fix_categories"].invoke
    Rake::Task["gm:sync_indexes:fix_categories_count"].invoke
    fix_categories_count
  end
  
  namespace :sync_indexes do
    desc "Se asegura de que todas las facciones tengan las categorías de contenidos necesarias"
    task :fix_categories => :environment do
      contents_categories = Cms.categories_classes
      msgs = ''
      
      for f in Faction.find(:all)
        g = Game.find_by_name(f.name)
        g = Platform.find_by_name(f.name) if g.nil?
        puts f.name
        for ctype in contents_categories
          if not ctype.find(:first, :conditions => ['parent_id is null and id = root_id and code = ?', f.code]) then
            ctype.new({:name => f.name, :code => g.code}).save
            msgs = "#{msgs}<br />Creada categoría en #{ctype.name} para #{f.name}"
          end
          
          # guardamos para asegurarnos que root_id se ponga
          ctype.find(:first, :conditions => ['parent_id is null and id = root_id and code = ?', f.code]).save
        end
      end
      # TODO foros
    end
    
    desc "Recalcula el campo items_count de cada categoría"
    task :fix_categories_count => :environment do
      contents_categories = [DemosCategory, DownloadsCategory, TutorialsCategory, TopicsCategory, ImagesCategory]
      msg = ''
      
      for cls in contents_categories
        for d in cls.find(:all)
          d.items_count(nil, true)
        end
        msg ="#{msg}<br />Recalculados elementos en #{cls.name}"
        # TODO no borra las caches de páginas
      end
    end
  end
  
  
  desc "Se asegura de que todos los clanes tengan las categorías de contenidos necesarias"
  task :sync_clans_categories => :environment do
    msgs = ''    
    for clan in Clan.find(:all, :conditions => 'id in (select clan_id from portals where clan_id is not null)', :order => 'id')
      for ctype_name in Cms::CLANS_CONTENTS
        cat_cls = Object.const_get(ctype_name).category_class
        if not cat_cls.find(:first, :conditions => ['parent_id is null and id = root_id and clan_id = ?', clan.id]) then
          new_cat = cat_cls.create({:name => clan.name, :code => clan.tag, :clan_id => clan.id})
          puts new_cat.errors.full_messages if new_cat.new_record?
          puts "Categoría #{ctype_name} para #{clan.name} missing, creando.."
          new_cat.children.create({:name => 'General', :code => 'general', :clan_id => clan.id}) if ctype_name == 'Topic'
          new_cat.save # guardamos para asegurarnos que root_id se ponga
        end
      end
    end
  end
end