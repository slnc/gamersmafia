class Gm1625 < ActiveRecord::Migration
  def self.up
    execute "INSERT INTO products(name, price, description, cls) VALUES('Firma en comentarios', 25.0, 'Te permite poner una breve firma al final de tus comentarios.', 'SoldCommentsSig');"
    slonik_execute "alter table users add column enable_comments_sig bool not null default 'f';"
    slonik_execute "alter table users add column comments_sig varchar;"
    slonik_execute "alter table users add column comment_show_sigs bool;"
    slonik_execute "create unique index users_comments_sig on users(comments_sig);"
    execute "UPDATE users SET enable_comments_sig = 't', comments_sig = 'Regards las plantas' where login='SinSa';"
    puts "CREAR ABTEST mostrar firmas por defecto"
  end

  def self.down
  end
end
