# -*- encoding : utf-8 -*-
require 'has_slug'
class GamingPlatform < ActiveRecord::Base
  validates_format_of :name, :with => /^[a-z0-9':[:space:]-]{1,36}$/i
  validates_uniqueness_of :name
  has_many :terms
  has_slug

  def code
    self.slug
  end

  def create_contents_categories
    root_term = Term.create({
        :gaming_platform_id => self.id,
        :name => self.name,
        :slug => self.slug,
        :taxonomy => "GamingPlatform",
    })

    Organizations::DEFAULT_CONTENTS_CATEGORIES.each do |c|
      new_term = root_term.children.create(:name => c[1], :taxonomy => c[0])
      raise new_term.errors.full_messages_html if new_term.new_record?
    end
  end

  def faction
    Faction.find_by_code(self.slug)
  end

  # TODO copypaste de game
  def update_slug_in_other_places_if_changed
    [:slug, :name].each do |thing|
      next unless self.slug_changed?

      old_value = self.changes[thing][0]
      return if old_value.nil?
      f = Faction.send("find_by_#{thing}", old_value)
      f.send(thing, self.send(thing))
      f.save
      Cms::CONTENTS_WITH_CATEGORIES.each do |content_name|
        root_cat = Object.const_get(
          content_name).category_class.find(
            :first,
            :conditions =>["thing = #{thing} and id = root_id",
                           old_value])
        root_cat.send(thing, self.send(thing))
        root_cat.save
      end
    end
    true
  end

  # TODO copypaste de Game.rb
  after_save :update_img_file
  after_save :update_slug_in_other_places_if_changed

  def file=(incoming_file)
    @temp_file = incoming_file
    @filename = incoming_file.original_filename if incoming_file.to_s != ''
    @content_type = incoming_file.content_type if incoming_file.to_s != ''
  end

  def update_img_file
    if @temp_file and @filename != ''
      File.open(self.img_file, "wb+") do |f|
        f.write(@temp_file.read)
      end
      Skins.update_default_skin_styles
      @temp_file = nil
      #self.path = "/storage/games/#{self.slug}.gif"
      #self.save
    end
  end

  def has_img_file?
    File.exists?(self.img_file)
  end

  def img_file
    "#{Rails.root}/public/storage/games/#{self.slug}.gif"
  end
end
