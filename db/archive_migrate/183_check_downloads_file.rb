class CheckDownloadsFile < ActiveRecord::Migration
  def self.up
    Download.find(:all, :conditions => ['state = ? AND file is NOT NULL and file <> \'\'', Cms::PUBLISHED], :order => 'id DESC').each do |d|
      if !File.exists?("#{Rails.root}/public/#{d.file}") && d.download_mirrors.count == 0
        puts "#{d.id.to_s.ljust(6, ' ')} #{d.file}"
        User.db_query("UPDATE downloads SET file = NULL WHERE id = #{d.id}")
      end
    end and nil
  end

  def self.down
  end
end
