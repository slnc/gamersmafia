class Gm1241 < ActiveRecord::Migration
  def self.up
    #TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO 
  
    if nil then 
    slonik_execute "alter table friends_users add column id serial primary key not null unique;"
    slonik_execute "alter table friends_users add column created_on timestamp not null default now();"
    slonik_execute "alter table friends_users add column accepted_on timestamp;"
    
    slonik_execute "alter table friends_users add column receiver_email varchar;"
    slonik_execute "alter table friends_users add column invitation_text varchar;"
    slonik_execute "alter table friends_users add column external_invitation_key char(32) unique;"
    slonik_execute "alter table friends_users rename column user_id to sender_user_id;"
    slonik_execute "alter table friends_users rename column friend_id to receiver_user_id;"
    slonik_execute "alter table friends_users rename to friendships;"
    slonik_execute "alter table friendships drop constraint \"friends_users_friend_user_id_fkey\";"
    slonik_execute "alter table friendships add foreign key(receiver_user_id) references users match full;"
    slonik_execute "alter table friendships alter column receiver_user_id drop not null;"
    end
    # slonik_execute "create view friendships as select id, user_id as sender_user_id, friend_id as receiver_user_id, created_on, accepted_on, receiver_email, invitation_text, external_invitation_key from friends_users;"
    # buscamos las amistades recíprocas, nos quedamos con una y le ponemos el accepted_on
    already_friends = [] # hash ordenado por user ids, primero el mas peq
    puts "initial friendships: #{Friendship.count}"
    Friendship.find(:all, :conditions => 'accepted_on IS NULL AND receiver_user_id IS NOT NULL', :order => 'sender_user_id, receiver_user_id').each do |f|
      if f.sender_user_id > f.receiver_user_id
        k = "#{f.receiver_user_id}.#{f.sender_user_id}"
      else
        k = "#{f.sender_user_id}.#{f.receiver_user_id}"
      end
      
      if already_friends.include?(k) then # estamos en la segunda
        puts "found relationship #{k}, deleting duped and saving previous"
        f2 = Friendship.find_between(f.sender, f.receiver, f.id)
        raise "no se ha encontrado segunda relacion para #{f.id}" unless f2
        raise "#{k} encontrada pero friendships iguales #{f.id} #{f2.id}!" if f.id == f2.id
        # NO USAR f2.accept
        f2.accepted_on = Time.now
        f2.save
        f.destroy
      end
      
      already_friends<< k
    end
    puts "final friendships: #{Friendship.count}"
    raise "ah"
    
    # creamos la uniq_constraint
    # TODO el campo accepted_on
  end
  
  def self.down
  end
end

