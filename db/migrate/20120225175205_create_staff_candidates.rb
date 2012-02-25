class CreateStaffCandidates < ActiveRecord::Migration
  def change
    User.db_query(<<-END
    CREATE TABLE staff_candidates(
        id serial primary key not null,
        staff_position_id int not null references staff_positions(id) match full,
        created_on timestamp not null default now(),
        updated_on timestamp not null default now(),
        user_id int not null references users(id) match full,
        key_result1 varchar,
        key_result2 varchar,
        key_result3 varchar
    );
    END
    )
  end
end
