class FactionLowerRolesToUserRoles < ActiveRecord::Migration
  def self.up
    FactionsCapo.find(:all).each do |fc|
      fc.faction.add_moderator(fc.user)
    end
    
    FactionsEditor.find(:all).each do |fe|
      fe.faction.add_editor(fe.user, fe.content_type)
    end
  end
  
  def self.down
  end
end
