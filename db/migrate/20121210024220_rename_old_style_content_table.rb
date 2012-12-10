class RenameOldStyleContentTable < ActiveRecord::Migration
  def up
    execute "alter table news rename to old_news;"
    execute "alter table bets rename to old_bets;"
    execute "alter table images rename to old_images;"
    execute "alter table downloads rename to old_downloads;"
    execute "alter table topics rename to old_topics;"
    execute "alter table polls rename to old_polls;"
    execute "alter table events rename to old_events;"
    execute "alter table coverages rename to old_coverages;"
    execute "alter table tutorials rename to old_tutorials;"
    execute "alter table interviews rename to old_interviews;"
    execute "alter table columns rename to old_columns;"
    execute "alter table reviews rename to old_reviews;"
    execute "alter table funthings rename to old_funthings;"
    execute "alter table blogentries rename to old_blogentries;"
    execute "alter table demos rename to old_demos;"
    execute "alter table questions rename to old_questions;"
    execute "alter table recruitment_ads rename to old_recruiment_ads;"
  end

  def down
  end
end
