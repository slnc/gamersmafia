class CreateStaffCandidateVotes < ActiveRecord::Migration
  def change
    User.db_query(<<-END
    CREATE TABLE staff_canditate_votes(
        id serial primary key not null,
        user_id int not null references users(id) match full,
        created_on timestamp not null default now(),
        staff_candidate_id int not null references staff_candidates match full,


    );
    END
    )
  end
end
