class CreateNewTermsTopography < ActiveRecord::Migration
  def self.up
    [Game, Platform, BazarDistrict].each do |cls|
      cls.find(:all).each do |thing|
        Term.create(:name => thing.name, :slug => thing.code.bare, "#{Inflector::underscore(cls.name)}_id".to_sym => thing.id)
      end
    end
    #[Clan].each do |cls|
    #  cls.find(:all).each do |thing|
    #    Term.create(:name => thing.name, :slug => thing.tag.bare, "#{Inflector::underscore(cls.name)}_id".to_sym => thing.id)
    #  end
    #end
    Term.create(:name => 'Gamersmafia', :slug => 'gm') unless Term.single_toplevel(:slug => 'gm')
    Term.create(:name => 'Otros', :slug => 'otros') unless Term.single_toplevel(:slug => 'otros')  # TODO
    Term.create(:name => 'Bazar', :slug => 'bazar')  unless Term.single_toplevel(:slug => 'bazar') # TODO
    Term.create(:name => 'Partys', :slug => 'partys')  unless Term.single_toplevel(:slug => 'partys') # TODO
    Term.create(:name => 'Especiales', :slug => 'especiales')  unless Term.single_toplevel(:slug => 'especiales') # TODO
    contentsclasses = Cms::CONTENTS_WITH_CATEGORIES
    contentsclasses.each do |contentclsname|
      cls = Object.const_get("#{Inflector::pluralize(contentclsname)}Category")
      puts cls.name
      cls.find(:all, :order => 'id').each do |o|
        puts "(#{o.root.name}) #{o.name} #{o.code}"
        next if o.respond_to?(:clan_id) && o.clan_id # ignoramos categorias de clanes
        # para cada categoria
        base_term = Term.find(:first, :conditions => ["id = root_id AND slug = ?", o.root.code.bare]) if o.root.code
        base_term = Term.find(:first, :conditions => ["id = root_id AND lower(name) = lower(?)", o.root.name]) if base_term.nil?
        
        if base_term.nil?
          base_term = Term.new(:name => o.root.name, :slug => o.root.code.bare) if base_term.nil?
          base_term.set_import_mode
          base_term.save
          puts "ERROR: Imposible encontrar base_term para #{cls.name}(#{o.root.code.bare}, #{o.root.name}), creada categoría"
          # 
          #next
        end
        if o.id != o.root_id
          new_term = base_term.mirror_category_tree(o, cls.name)
        else
          new_term = base_term
        end
        # buscamos el ultimo content de esta categoria tagueado
        # lastct = new_term.contents.find(:first, :order => 'id DESC') ContentTerm.find(:first, )
        # guardamos asociación de todos los items de esta categoría con el term
        o.find(:all, :conditions => "#{Inflector::underscore(o.class.name)}_id = #{o.id}", :order => 'id').each { |item| new_term.link(item.unique_content, false) }
      end
    end
  end

  def self.down
  end
end
