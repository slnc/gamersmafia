class ReasonForChoice < ActiveRecord::Migration
  def up
    execute "alter table decision_user_choices add column custom_reason varchar;"
    execute "alter table decision_user_choices add column canned_reason_id varchar;"
  end

  def down
  end
end
