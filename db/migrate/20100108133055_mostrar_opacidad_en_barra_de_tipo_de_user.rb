class MostrarOpacidadEnBarraDeTipoDeUser < ActiveRecord::Migration
  def self.up
    execute "alter table users add column cache_valorations_weights_on_self_comments numeric;"
    execute "alter table global_vars add column max_cache_valorations_weights_on_self_comments numeric;"
    User.find(:all).each do |u| u.valorations_weights_on_self_comments end
    execute "update global_vars set max_cache_valorations_weights_on_self_comments = (select max(cache_valorations_weights_on_self_comments) from users where cache_valorations_weights_on_self_comments is not null);"
  end

  def self.down
  end
end
