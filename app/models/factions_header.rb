class FactionsHeader < ActiveRecord::Base
    after_save :update_img_file
    after_destroy :delete_files
    has_many :portal_headers, :dependent => :destroy

    def file=(incoming_file)
        @temp_file = incoming_file
        @filename = incoming_file.original_filename
        @content_type = incoming_file.content_type
    end

    def update_img_file
      fullpath = "#{Rails.root}/public/storage/factions_headers/#{self.faction_id}/#{self.id}.jpg"

      if not File.exists?((File.dirname(fullpath)))then
          FileUtils.mkdir_p File.dirname(fullpath)
      end

      if @temp_file and @filename != ''
        thumb_path = "#{Rails.root}/public/cache/thumbnails/f/500x60/storage/factions_headers/#{self.faction_id}/#{self.id}.jpg"
        if File.exists?(thumb_path) then
          File.unlink(thumb_path)
        end

        File.open(fullpath, "wb+") do |f| 
          f.write(@temp_file.read)
        end
        @temp_file = nil
      end
    end

    def delete_files
      fullpath = "#{Rails.root}/public/storage/factions_headers/#{self.faction_id}/#{self.id}.jpg"
      if File.exists?(fullpath) then
        File.unlink(fullpath)
      end
    end
end
