load 'Rakefile'

class CrearCatsDePreguntas < ActiveRecord::Migration
  def self.up
    Rake::Task["gm:sync_indexes:fix_categories"].invoke
  end

  def self.down
  end
end
