class CreateDecisionUserChoices < ActiveRecord::Migration
  def change
    execute "create table decision_choices(
      id serial primary key not null unique,
      decision_id int not null references decisions match full on delete cascade,
      name varchar
      );"
   execute("create index decision_choices_common on decision_choices(decision_id);")


    execute "create table decision_user_choices(
      id serial primary key not null unique,
      decision_id int not null references decisions match full on delete cascade,
      user_id int not null references users match full on delete cascade,
      decision_choice_id int not null references decision_choices match full on delete cascade,
      created_on timestamp not null default now(),
      updated_on timestamp not null default now(),
      probability_right float not null
      );"
   execute("create index decision_user_choices_uniq on decision_user_choices(decision_id, user_id);")


    execute "create table decision_comments(
      id serial primary key not null unique,
      decision_id int not null references decisions match full on delete cascade,
      user_id int not null references users match full on delete cascade,
      created_on timestamp not null default now(),
      updated_on timestamp not null default now(),
      comment varchar
      );"
   execute("create index decision_comments_decision_idx on decision_comments(decision_id);")
   execute("create index decision_comments_user_idx on decision_comments(user_id);")

   execute("alter table decisions add column final_decision_choice_id int references decision_choices on delete set null;");
   execute("create index decision_final_decision_choice_id on decisions(final_decision_choice_id);");
   execute("alter table decisions add constraint decisions_final_fk foreign key(final_decision_choice_id) references decision_choices match full on delete set null;");
  end
end
