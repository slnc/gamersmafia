class AddIndexesToUsersContentsTags < ActiveRecord::Migration
  def self.up
slonik_execute "create index users_contents_tags_user_id on users_contents_tags(user_id);"

slonik_execute "create index users_contents_tags_term_id on users_contents_tags(term_id);"

slonik_execute "create index users_contents_tags_content_id on users_contents_tags(content_id);"

  end

  def self.down
  end
end
