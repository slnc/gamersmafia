class AddFkReusrrected < ActiveRecord::Migration
  def up
    User.db_query("alter table users add constraint resurrected_by_user_idfk foreign key (resurrected_by_user_id) references users;")
  end

  def down
  end
end
