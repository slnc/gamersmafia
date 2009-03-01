class ForgetOldTr < ActiveRecord::Migration
  def self.up
    slonik_execute "create table archive.treated_visitors (like public.treated_visitors);"
  end

  def self.down
  end
end
