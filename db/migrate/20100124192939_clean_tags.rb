class CleanTags < ActiveRecord::Migration
  def self.up
    execute "update users_contents_tags set original_name = LOWER(original_name);"
    execute "create index terms_lower_name on terms(LOWER(name));"
  end

  def self.down
  end
end
