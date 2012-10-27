class MigrateComments < ActiveRecord::Migration
  def up
    execute "alter table comments add column comment_unformatized text;"
    execute "update comments set comment_unformatized = comment;"

    count = 0
    Comment.find_each(:batch_size => 10000) do |comment|
      comment.update_column(:comment, Formatting.html_to_bbcode(comment.comment))
      count += 1
      puts count if count % 10000 == 0
    end
  end

  def down
  end
end
