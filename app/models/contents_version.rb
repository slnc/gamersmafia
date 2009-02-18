class ContentsVersion < ActiveRecord::Base
  belongs_to :content
  serialize :data
end
