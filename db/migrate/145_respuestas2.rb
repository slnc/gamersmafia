class Respuestas2 < ActiveRecord::Migration
  def self.up
    execute "INSERT INTO content_types(name) VALUES('Question');"
  end

  def self.down
  end
end
