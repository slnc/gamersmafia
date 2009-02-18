class Gm1343 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table news drop column deleted;"
    slonik_execute "alter table bets drop column deleted;"
    slonik_execute "alter table images drop column deleted;"
    slonik_execute "alter table downloads drop column deleted;"
    slonik_execute "alter table demos drop column deleted;"
    slonik_execute "alter table polls drop column deleted;"
    slonik_execute "alter table events drop column deleted;"
    slonik_execute "alter table tutorials drop column deleted;"
    slonik_execute "alter table interviews drop column deleted;"
    slonik_execute "alter table columns drop column deleted;"
    slonik_execute "alter table reviews drop column deleted;"
    slonik_execute "alter table funthings drop column deleted;"
    slonik_execute "alter table blogentries drop column deleted;"
    slonik_execute "alter table topics drop column deleted;"
    slonik_execute "alter table coverages drop column deleted;"
  end

  def self.down
  end
end
