class RemoveNotNullExternalId < ActiveRecord::Migration
  def up
    execute "alter table contents alter column external_id drop not null;"
  end

  def down
  end
end
