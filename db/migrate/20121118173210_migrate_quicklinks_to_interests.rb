class MigrateQuicklinksToInterests < ActiveRecord::Migration
  def up
    UsersPreference.find(:all, :conditions => "name = 'quicklinks").each do |upref|
      upref.value.each do |qlink|
        t = Term.with_taxonomies(%s(Game GamingPlatform BazarDistrict Homepage)).find_by_slug(qlink[:code])
        if t
          if upref.user.create_interest(:entity_type_class => "Term", :entity_id => t.id)
            puts "Migrated quicklink #{t.name} for #{upref.login}"
          else
            puts "Error migrating quicklink #{t.name} for #{upref.login}"
          end
        end
      end
    end
  end

  def down
  end
end
