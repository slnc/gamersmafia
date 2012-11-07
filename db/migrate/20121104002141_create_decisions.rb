class CreateDecisions < ActiveRecord::Migration
  def change
    execute "create table decisions(
      id serial primary key not null unique,
      decision_type_class varchar not null,
      choice_type_id int not null,
      created_on timestamp not null default now(),
      updated_on timestamp not null default now(),
      state int not null,
      min_user_choices int not null,
      context text);"

    execute "create index decisions_type_class_state on decisions(decision_type_class, state);"

    execute "create table decision_user_reputations(
      id serial primary key not null unique,
      decision_type_class varchar not null,
      user_id int not null references users match full on delete cascade,
      created_on timestamp not null default now(),
      updated_on timestamp not null default now(),
      probability_right float not null);
    "

    execute "create unique index decisions_user_reputation_uniq on decision_user_reputations(user_id, decision_type_class);"

  end
end
