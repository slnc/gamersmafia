class CreateDownloadsToplevelCat < ActiveRecord::Migration
  def self.up
    DownloadsCategory.create(:code => 'bazar', :name => 'Bazar')
  end

  def self.down
  end
end
