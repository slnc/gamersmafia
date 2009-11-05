class CommentViolationOpinions < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table comments add column random_v decimal not null default random()"
    slonik_execute "create index comments_random_v on comments(random_v);"
    slonik_execute "create table comment_violation_opinions (id serial primary key not null unique, user_id int not null references users, comment_id int not null references comments not null, cls smallint not null);"
    slonik_execute "create unique index comment_violation_opinion on comment_violation_opinions(user_id, comment_id);"
  end

  def self.down
  end
end
