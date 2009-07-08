class DownloadMirror < ActiveRecord::Base
    belongs_to :download
    validates_format_of :url, :with => Cms::URL_REGEXP_FULL
end
