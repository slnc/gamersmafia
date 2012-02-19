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

    org = BazarDistrict.find_by_code(maincat.root.code)
    return org unless org.nil?
  end

  def self.change_organization_type(obj, new_cls)
    raise "Error: #{obj.name} ya es #{new_cls.name}" if obj.class.name == new_cls.name
    raise "unsupported" unless obj.class.name == 'Faction' && new_cls.name == 'BazarDistrict'

    ActiveRecord::Base.transaction do
      # TODO no se migran avatares, etc
      # WARNING ESTO ES SOLO PARA PASAR DE FACTION A BAZAR_DISTRICT
      portal = Portal.find_by_code(obj.code)

      User.db_query("UPDATE portals SET type = 'BazarDistrictPortal' WHERE id = #{portal.id}")
      root_term = Term.single_toplevel(:slug => obj.code)
      root_term.game_id = nil
      root_term.platform_id = nil
      root_term.save
      bd = BazarDistrict.create(:name => obj.name, :code => obj.code)
      root_term.bazar_district_id = bd.id
      root_term.save
      refthing = obj.referenced_thing
      User.db_query("UPDATE contents SET bazar_district_id = #{bd.id}, game_id = NULL WHERE #{refthing.class.name.downcase}_id = #{refthing.id}")
      bd.update_don(obj.boss)
      bd.update_mano_derecha(obj.underboss)

      obj.moderators.each do |mod|
        bd.add_sicario(mod)
      end

      obj.editors.each do |ctype, u|
        bd.add_sicario(u)
      end
      obj.avatars.each do |av|
        av.destroy(true)
      end
      obj.reload
      obj.destroy
      bd
    end
  end
end
