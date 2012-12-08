class AddColumnsToContents < ActiveRecord::Migration
  def change
    execute "alter table contents add column description text;"
    execute "alter table contents add column main text;"
    execute "alter table contents add column hits_registered int not null default 0;"
    execute "alter table contents add column hits_anonymous int not null default 0;"
    execute "alter table contents add column cache_rating smallint;"
    execute "alter table contents add column cache_rated_times smallint;"
    execute "alter table contents add column cache_comments_count smallint not null default 0;"
    execute "alter table contents add column log varchar;"
    execute "alter table contents add column cache_weighted_rank numeric(10, 2);"
    execute "alter table contents add column type varchar;"
    execute "update contents set type = (SELECT name from content_types WHERE id = content_type_id);"
    execute "alter table contents alter column type set not null"
    execute "alter table contents drop content_type_id;"
    execute "alter table contents drop is_public;"
  end
end
