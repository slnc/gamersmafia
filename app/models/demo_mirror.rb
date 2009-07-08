class DemoMirror < ActiveRecord::Base
  belongs_to :demo
  validates_format_of :url, :with => Cms::URL_REGEXP_FULL
end
