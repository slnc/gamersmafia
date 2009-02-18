class Gm2032 < ActiveRecord::Migration
  def self.up
    slonik_execute "alter table slog_entries add column reporter_user_id int references users match full;"
    slonik_execute "alter table slog_entries add column reviewer_user_id int references users match full;"
    slonik_execute "alter table slog_entries add column short_version varchar;"
    slonik_execute "alter table slog_entries add column long_version varchar;"
    execute "update slog_entries set reporter_user_id = (select id from users where login='MrAchmed');"
    execute "update slog_entries set reviewer_user_id = (select id from users where login='MrAchmed') where created_on < now() - '1 month'::interval;"
    execute "update slog_entries set type_id = #{SlogEntry::TYPES[:emergency_antiflood]} WHERE headline like 'Antiflood de seguridad impuesto%';"
    execute "update slog_entries set type_id = #{SlogEntry::TYPES[:multiple_accounts]} WHERE headline like 'Registro desde una ip existente%';"
    execute "update slog_entries set type_id = #{SlogEntry::TYPES[:content_report]} WHERE headline like 'Contenido%';"
    # update slog_entries set type_id = 5 WHERE headline like 'Contenido%';
  end

  def self.down
  end
end
