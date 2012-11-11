# -*- encoding : utf-8 -*-
module Organizations
  # Organizaciones son facciones y distritos
  # organizaciones tienen que responder a user_is_editor_of_content_type?
  DEFAULT_CONTENTS_CATEGORIES = [
     ['DownloadsCategory', 'General'],
     ['TopicsCategory', 'General'],
     ['TopicsCategory', 'Ayuda'],
     ['ImagesCategory', 'General'],
     ['TutorialsCategory', 'General'],
     ['QuestionsCategory', 'General'],
    ]

  def self.find_by_content(obj)
    obj = obj.real_content if obj.class.name == 'Content'
    obj = obj.content.real_content if obj.class.name == 'Comment'
    return nil unless Cms::CONTENTS_WITH_CATEGORIES.include?(obj.class.name)

    maincat = obj.main_category
    return if maincat.nil?

    org = Faction.find_by_code(maincat.root.code)
    return org unless org.nil?

    # las categorias de distritos cuelgan de bazar

    org = BazarDistrict.find_by_slug(maincat.root.code)
    return org unless org.nil?
  end
end
