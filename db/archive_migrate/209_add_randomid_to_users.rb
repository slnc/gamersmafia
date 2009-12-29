class AddRandomidToUsers < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table users add column random_id float8 default random();"
    slonik_execute "create index users_random_id on users(random_id);"
    5.times do |t|
      execute "update users set random_id = random() where id BETWEEN 1 AND 10000"
    end
    puts "TODO a;adir mas RANDOM IDS a users!!"
  end

  def self.down
  end
end
