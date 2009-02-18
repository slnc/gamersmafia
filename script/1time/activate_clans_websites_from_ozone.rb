Clan.find(:all, :conditions => 'simple_mode = \'f\'').each { |c| c.activate_website }
