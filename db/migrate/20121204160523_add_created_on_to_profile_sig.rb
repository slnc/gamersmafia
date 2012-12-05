class AddCreatedOnToProfileSig < ActiveRecord::Migration
  def change
    execute "alter table profile_signatures add column created_on timestamp not null default now();"
  end
end
