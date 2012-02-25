class CreateStaffPositions < ActiveRecord::Migration
  def change
    User.db_query(<<-END
    CREATE TABLE staff_types(
        id serial primary key not null,
        staff_type_id int not null references staff_types(id) match full,
        state varchar not null default 'unassigned',
        term_started_on timestamp,
        term_ends_on timestamp,
        staff_candidate_id int,
        );
    END
    )
    puts "Create foreign key constraint on staff_types!"
  end
end
