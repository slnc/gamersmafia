class ModifyStaffCandidates < ActiveRecord::Migration
  def up
    User.db_query("alter table staff_candidates alter column term_starts_on set not null;")
    User.db_query("alter table staff_candidates alter column term_ends_on set not null;")
    User.db_query("create unique index staff_candidates_uniq on staff_candidates(staff_position_id, user_id, term_starts_on);")
    User.db_query("alter table staff_positions rename column term_started_on to term_starts_on;")
    User.db_query("alter table staff_positions alter column term_starts_on type date;")
    User.db_query("alter table staff_positions alter column term_ends_on type date;")
    User.db_query("alter table staff_candidates alter column term_ends_on type date;")
    User.db_query("alter table staff_candidates alter column term_starts_on type date;")
  end

  def down
  end
end
