namespace :gm do
  desc "Sync mailling list subscribers"
  task :sync_ml => :environment do
    total = User.count('confirmed=1 and email <> \'\'')
    puts "Total: #{total}"
    
    i = 0
    for u in User.find(:all, :conditions => 'confirmed=1 and email <> \'\'')
      i += 1
      
      if not u.email.match(/^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[A-Za-z]{2,})$/) then
        next
      end
      
      if u.notifications_global && !u.banned && !u.disabled && u.confirmed == 1 then
        `sudo ezmlm-sub /home/vpopmail/domains/2/gamersmafia.com/avisos/ #{u.email}`
      else
        `sudo ezmlm-unsub /home/vpopmail/domains/2/gamersmafia.com/avisos/ #{u.email}`
      end
      
      if i % (total / 100) == 0 then
        puts "#{(i*(100/total.to_f)).ceil}%"
      end
    end
  end
end
