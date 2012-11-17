class Dropoldpub < ActiveRecord::Migration
  def up
    execute "drop table publishing_personalities;"
    execute "drop table publishing_decisions;"
  end

  def down
  end
end
