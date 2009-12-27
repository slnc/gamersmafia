class AddSourceToContents < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE contents ADD COLUMN source varchar;"
    %w(News Tutorial Column Interview Review).each do |cls_name|
      execute "ALTER TABLE #{ActiveSupport::Inflector::tableize(cls_name)} ADD COLUMN source varchar;"
    end
  end

  def self.down
  end
end
