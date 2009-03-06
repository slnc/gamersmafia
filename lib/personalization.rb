module Personalization
  MAX_QUICKLINKS = 10
  def self.add_quicklink(u, code, link)
    qlinks = self.load_quicklinks(u)
    return if qlinks.size >= MAX_QUICKLINKS
    found = false
    qlinks.each do |ql| 
      if ql[:code] == code
        found = true
        break
      end
    end
    return if found
    qlinks << {:code => code, :url => link}
    u.pref_quicklinks = qlinks.uniq
    Cache::Personalization.expire_quicklinks(u)
  end
  
  def self.load_quicklinks(u)
    u.pref_quicklinks || Array.new
  end
  
  def self.del_quicklink(u, code)
    qlinks = self.load_quicklinks(u)
    u.pref_quicklinks = qlinks.delete_if { |a| a[:code] == code}
    Cache::Personalization.expire_quicklinks(u)
  end
  
  def self.clear_quicklinks(u)
    u.pref_quicklinks = nil
    Cache::Personalization.expire_quicklinks(u)
  end
  
  def self.quicklinks_for_user(u)
    qlinks = self.load_quicklinks(u)
    codes = qlinks.collect { |a| a[:code] }
    
    # TODO añadir facciones de las que eres editor/moderador
    if u.faction_id && !codes.include?(u.faction.code)
      qlinks << {:code => u.faction.code, :url => "http://#{u.faction.code}.#{App.domain}/"}
    end
        
    u.users_roles.find(:all, :conditions => "role IN ('Don', 'ManoDerecha', 'Sicario')").each do |ur|
      bd = BazarDistrict.find(ur.role_data.to_i)
      qlinks << {:code => bd.code, :url => "http://#{bd.code}.#{App.domain}"} unless codes.include?(bd.code)
    end
    
    qlinks.uniq[0..MAX_QUICKLINKS]
  end
  
  
  def self.load_user_forums(u)
    u.pref_user_forums || [[], [], []]
  end
  
  def self.default_user_forums
    # TODO aqui se podria aplicar inteligencia en base al historial de navegación del usuario
    # TODO no tenemos updated_on en terms asi que usamos el id del ultimo el actualizado para elegir los foros por defecto
    Term.find(:all, :conditions => 'id = root_id', :order => 'last_updated_item_id DESC', :limit => 12).collect {|tc| tc.id }.chunk(3)
  end
  
  def self.get_user_forums(u)
    uf = self.load_user_forums(u)
    uf = self.populate_user_forums(u) if uf.size == 0
    uf
  end
  
  def self.populate_user_forums(u)
    # raise "fail"
    [[], [], []]
  end
  
  def self.update_user_forums_order(u, bucket1, bucket2, bucket3)
    u.pref_user_forums = [bucket1.collect {|i| i.to_i }, bucket2.collect {|i| i.to_i }, bucket3.collect {|i| i.to_i }] # 3 buckets
  end
  
  def self.add_user_forum(u, id, link)
    user_forums = self.load_user_forums(u)
    user_forums[0] = user_forums[0].each { |ql| return if ql == id.to_i }
    user_forums[1] = user_forums[1].each { |ql| return if ql == id.to_i }
    user_forums[2] = user_forums[2].each { |ql| return if ql == id.to_i }
    if (user_forums[1].size < user_forums[0].size)
      dst = 1
    elsif (user_forums[2].size < user_forums[1].size)
      dst = 2
    else
      dst = 0
    end
    
    user_forums[dst] << id.to_i
    u.pref_user_forums = user_forums
  end
  
  def self.del_user_forum(u, id)
    user_forums = self.load_user_forums(u)
    user_forums[0] = user_forums[0].delete_if { |a| a == id.to_i}
    user_forums[1] = user_forums[1].delete_if { |a| a == id.to_i}
    user_forums[2] = user_forums[1].delete_if { |a| a == id.to_i}
    u.pref_user_forums = user_forums 
  end
end