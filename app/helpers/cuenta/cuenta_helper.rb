module Cuenta::CuentaHelper
  def role_data(ur)
    case ur.role
      when 'Advertiser':
      adv = Advertiser.find(ur.role_data.to_i)
        "Anunciante (<strong>#{adv.name}</strong>)"
        
      when 'Boss':
      f = Faction.find(ur.role_data.to_i)
        "Boss de <strong><a href=\"http://#{f.code}.#{App.domain}\">#{f.name}</a></strong>"
        
      when 'Underboss':
      f = Faction.find(ur.role_data.to_i)
        "Underboss de <strong><a href=\"http://#{f.code}.#{App.domain}\">#{f.name}</a></strong>"
      
      when 'Don':
      bd = BazarDistrict.find(ur.role_data.to_i)
        "Don de <strong><a href=\"http://#{bd.code}.#{App.domain}\">#{bd.name}</a></strong>"
        
      when 'ManoDerecha':
      bd = BazarDistrict.find(ur.role_data.to_i)
        "Mano derecha de <strong><a href=\"http://#{bd.code}.#{App.domain}\">#{bd.name}</a></strong>"
        
      when 'Sicario':
      bd = BazarDistrict.find(ur.role_data.to_i)
        "Sicario de <strong><a href=\"http://#{bd.code}.#{App.domain}\">#{bd.name}</a></strong>"
        
      when 'GroupMember':
      g = Group.find(ur.role_data.to_i)
        "Miembro del grupo <strong><a href=\"http://#{App.domain}/grupos/grupo/#{g.id}\">#g.name}</a></strong>"
        
      when 'GroupAdministrator':
      g = Group.find(ur.role_data.to_i)
        "Administrador del grupo <strong><a href=\"http://#{App.domain}/grupos/grupo/#{g.id}\">#g.name}</a></strong>"
        
      when 'Moderator':
      f = Faction.find(ur.role_data.to_i)
        "Moderador de <strong><a href=\"http://#{f.code}.#{App.domain}\">#{f.name}</a></strong>"
        
      when 'Editor':
      f = Faction.find(ur.role_data_yaml[:faction_id].to_i)
      ctype = ContentType.find(ur.role_data_yaml[:content_type_id].to_i)
        "Editor de <strong>#{Cms::CLASS_NAMES[ctype.name].pluralize}</strong> en <strong><a href=\"http://#{f.code}.#{App.domain}\">#{f.name}</a></strong>"
      when 'CompetitionAdmin':
      c = Competition.find(ur.role_data.to_i)
      "Admin de <strong><a href=\"http://#{App.arena}/competiciones/show/#{c.id}\">#{c.name}</a></strong>"
      
      when 'CompetitionSupervisor':
      c = Competition.find(ur.role_data.to_i)
      "Supervisor de <strong><a href=\"http://#{App.arena}/competiciones/show/#{c.id}\">#{c.name}</a></strong>"
    else
      raise "role_data() of #{ur.role} is not implemented!"
    end
  end
end
