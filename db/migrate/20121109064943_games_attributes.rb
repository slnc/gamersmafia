class GamesAttributes < ActiveRecord::Migration
  def up
    execute "alter table games add column has_game_maps bool not null default 'f'"
    execute "alter table games add column has_competitions bool not null default 'f'"
    execute "alter table games add column has_demos bool not null default 'f'"
    execute "update games set has_game_maps = 't' WHERE id IN (SELECT DISTINCT(game_id) FROM games_maps);"
    execute "update games set has_competitions = 't' WHERE id IN (SELECT DISTINCT(game_id) FROM competitions);"
    execute "update games set has_demos = 't' WHERE id IN (SELECT (select game_id from games_maps where id = demos.games_map_id) FROM demos WHERE games_map_id is not null);"
    execute "create index games_has_game_maps on games(has_game_maps);"
    execute "create index games_has_competitions on games(has_competitions);"
    execute "create index games_has_demos on games(has_demos);"
  end

  def down
  end
end
