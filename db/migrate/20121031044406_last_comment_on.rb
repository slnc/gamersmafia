class LastCommentOn < ActiveRecord::Migration
  def up
    execute "alter table global_vars add column last_comment_on timestamp;"
    execute "alter table portals add column last_comment_on timestamp;"
  end

  def down
  end
end
