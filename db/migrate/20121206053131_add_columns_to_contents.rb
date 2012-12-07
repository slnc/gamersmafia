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
  end
end
