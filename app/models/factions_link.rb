class FactionsLink < ActiveRecord::Base
  belongs_to :faction
  file_column :image
  validates_presence_of :name, :url
end
