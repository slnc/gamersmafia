class PollPollsVotesCount < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table polls add column polls_votes_count int not null default 0;"
    Poll.find(:all, :order => 'id').each { p.recalculate_polls_votes_count }
  end

  def self.down
  end
end
