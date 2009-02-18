class CreateBazarDistricts < ActiveRecord::Migration
  def self.up
    slonik_execute "create table bazar_districts(id serial primary key not null unique, name varchar not null unique, code varchar not null unique);"
    [['Anime', 'anime'],  
      ['Cine y SeriesTV', 'cine'],
      ['Deportes', 'deportes'],
      ['Desarrollo', 'desarrollo'],
      ['Hardware', 'hw'],
      ['Informatica', 'informatica'],
      ['Internet', 'inet'],
      ['Musica', 'musica'],
      ['Vida Estudiante', 'estudiante'],
      ['Diseño', 'diseno']].each do |bdinfo|
        BazarDistrict.create({:name => bdinfo[0], :code => bdinfo[1]})
    end
    slonik_execute "alter table users_roles add column created_on timestamp not null default now();"
  end

  def self.down
    drop_table :bazar_districts
  end
end
