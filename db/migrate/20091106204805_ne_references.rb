class NeReferences < ActiveRecord::Migration
  def self.up
    slonik_execute "create table ne_references(id serial primary key not null unique, created_on timestamp not null, referenced_on timestamp not null, entity_class varchar not null, entity_id int not null, referencer_class varchar not null, referencer_id int not null);"
    slonik_execute "create unique index ne_references_uniq on ne_references(entity_class, entity_id, referencer_class, referencer_id);"
    slonik_execute "create index ne_references_entity on ne_references(entity_class, entity_id);"
    slonik_execute "create index ne_references_referencer on ne_references(referencer_class, referencer_id);"
    slonik_execute "alter table users add column login_is_ne_unfriendly bool not null default 'f';"
    slonik_execute "create index users_login_ne_unfriendly on users(login_is_ne_unfriendly);"
    #%w(pero como este mejor mola sea mal uno joder tan mierda alguien final nadie fin puta post contra tema jajaja hombre cara www culo jejeje demos cabeza ale feo entrar and malo foro mala gay mano serio interesante jaja internet nose sois madrid amigo ut2004 logo jur admin tonto -_- asin you hola ronda tres fake matar deck ordenador mmmm alto super windows minimo peta redentor poca papa noob megas luz chaval palabra counter cuesta valencia face torre negro curioso nah osp nano bugs raton guay suda masa cualquiera map perro map hijo amor viejo cabo bola fiesta manda padre amd ejem vicio pavo prueba papel pega 1000 good battlefield directo puerta love spam shot cacho tag jas).each do |l|
    %w(pero como este mejor mola sea mal uno joder tan mierda alguien final nadie fin puta post contra tema jajaja hombre cara www culo jejeje demos cabeza ale feo entrar and malo foro mala gay mano serio interesante jaja internet nose sois madrid amigo ut2004 logo jur admin tonto -_- asin you hola ronda tres fake matar deck ordenador mmmm alto super windows minimo peta redentor poca papa noob megas luz chaval palabra counter cuesta valencia face torre negro curioso nah osp nano bugs raton guay suda masa cualquiera map perro map hijo amor viejo cabo bola fiesta manda padre amd ejem vicio pavo prueba papel pega 1000 good battlefield directo puerta love spam shot cacho tag jas).each do |l|
      execute "update users set login_is_ne_unfriendly where login='#{l}'"
    end
  end

  def self.down
  end
end
