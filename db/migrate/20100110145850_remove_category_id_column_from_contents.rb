class RemoveCategoryIdColumnFromContents < ActiveRecord::Migration
  def self.up
    Cms::contents_classes.each do |cls|
      begin
        execute "alter table #{ActiveSupport::Inflector::tableize(cls.name)} drop column #{ActiveSupport::Inflector::tableize(cls.name)}_category_id;"
      rescue
      end
    end
  end
  
  def self.down
  end
end
