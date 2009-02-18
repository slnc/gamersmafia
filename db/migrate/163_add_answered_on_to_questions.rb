class AddAnsweredOnToQuestions < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table questions add column answered_on timestamp;"
    execute "update questions set answered_on = updated_on where accepted_answer_comment_id is not null;"
  end

  def self.down
  end
end
