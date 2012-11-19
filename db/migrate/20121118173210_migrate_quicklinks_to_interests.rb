class MigrateQuicklinksToInterests < ActiveRecord::Migration
  def up
    UsersPreference.find(:all, :conditions => "name = 'quicklinks'").each do |upref|
      next if upref.value.to_s == ""
      puts upref.value
      upref.value.each do |qlink|
        t = Term.with_taxonomies(%w(Game GamingPlatform BazarDistrict Homepage)).find_by_slug(qlink[:code])
        if t
          if upref.user.user_interests.create(:entity_type_class => "Term", :entity_id => t.id)
            puts "Migrated quicklink #{t.name} for #{upref.user.login}"
          else
            puts "Error migrating quicklink #{t.name} for #{upref.user.login}"
          end
        end
      end
    end
  end

  def down
  end
end
