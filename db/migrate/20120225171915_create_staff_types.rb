class CreateStaffTypes < ActiveRecord::Migration
  def change
    User.db_query(<<-END
    CREATE TABLE staff_types(
        id serial primary key not null,
        name varchar not null unique
    );
    END
    )
  end
end
