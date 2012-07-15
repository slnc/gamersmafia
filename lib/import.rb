# -*- encoding : utf-8 -*-
module Import
  module Contents
    def self.import(dba, cls)
      mrMan = User.find_by_login('mrman')
      obj = cls.new(dba)
      obj.save
      if obj.respond_to?(:state) && !dba.has_key?(:state)
        Cms::modify_content_state(obj, mrMan, Cms::PUBLISHED)
      end
      obj
    end
  end

  module Users
    def self.import(dbu)
      # importa el usuario representado por dbr. Ya debe tener todos los campos con los atributos correctos
      # import se encarga de modificar el valor de los atributos que estén fuera de rango
      # devuelve el id del usuario importado
      un = User.new(dbu)
      un.login = "#{un.login.ljust(3, 'a')}" if un.login.size < 3
      un.login = un.login.bare if !( /^[-a-zA-Z0-9_~.\[\]\(\)\:=|*^]{3,18}$/ =~ un.login)
      un.login = un.login[0..17] if un.login.size > 17
      un.email = "#{un.login}@nonexistant.com" if !(Cms::EMAIL_REGEXP =~ un.email.to_s )
      un.ipaddr = '127.0.0.1' if !(Cms::IP_REGEXP =~ un.ipaddr)
      dbu['username'] = un.login

      # (0) Si existe un usuario con el mismo login, el mismo email y misma contraseña -> perfect match
      # Warning para todos los demás
      # (1) Si coinciden login y email pero no contraseña se queda la contraseña de la web que visitase por última vez
      # (2) Si coinciden login y password pero no el email presuponemos que es la misma persona, se actualiza el email de la cuenta q se usó por última vez
      # (3) Si solo coinciden login si la cuenta de gm no se está usando desde hace más de 3 meses y tiene karma 0 se renombra la cuenta vieja para liberar el nick y se crea cuenta nueva
      # (4) Si solo coinciden login en caso de que (3) no se cumpla (renombramos la cuenta importada)
      # (5) Si no existe el nick pero hay otro usuario con mismo email si la contraseña coincide se migran las cuentas
      # (6) Si no existe el nick pero hay otro usuario con mismo email y distinta contraseña se unen tb
      # (7) En cualquier otro caso se crea la cuenta nueva
      # (8) Si hay otra cuenta con el mismo email asumimos que son la misma persona y los unimos
      if (u = User.find(:first, :conditions => ['lower(login) = lower(?)  AND lower(email) = lower(?) and password = ?', un.login, un.email, un.password]))
        un = u
        puts "no conflict | perfect match #{u.login}"
      elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?)  AND lower(email) = lower(?)', un.login, un.email]))
        un = u
        puts "no conflict | pw mismatch   #{u.login}"
      elsif (u = User.find(:first, :conditions => ['lower(email) = lower(?)', un.email]))
        puts "no conflict | email match   #{u.email}"
        un = u
      elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?)  AND password = ?', un.login, un.password]))
        un = u
        puts "no conflict | em mismatch   #{u.login}"
      elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?) AND cache_karma_points = 0 AND lastseen_on < now() - \'3 months\'::interval', un.login]))
        new_name_i = 1
        o_login = u.login
        u.login = "#{o_login}#{new_name_i}"
        u.email = "#{u.login}@nonexistant.com" if !(Cms::EMAIL_REGEXP =~ u.email.to_s )
        while !u.save
          puts u.errors.full_messages
          new_name_i += 1
          u.login = "#{o_login}#{new_name_i}"
        end
        puts "login conflict, old gm acc unused, imported account gets login #{un.login}"
      elsif (u = User.find(:first, :conditions => ['lower(login) = lower(?)', un.login]))
        new_name_i = 1
        o_login = un.login
        un.login = "#{o_login}#{new_name_i}"
        while !un.save # TODO si la cuenta no se guarda por otra causa esto peta
          puts un.errors.full_messages
          new_name_i += 1
          un.login = "#{o_login}#{new_name_i}"
        end
        User.db_query("UPDATE users SET password = '#{dbu[:password]}' WHERE id = #{un.id}")
        puts "login conflict, old gm acc used, renaming imported acc login #{un.login}"
      else # no nick conflict
        if (u = User.find(:first, :conditions => ['lower(email) = lower(?) and password = ?', un.email, un.password]))
          puts "email & password match, forget old login (#{un.login})\n"
          un = u
        elsif (u = User.find(:first, :conditions => ['lower(email) = lower(?)', un.email]))
          un = u
          puts "email match, assume it's same user and forget imported login and pass (#{un.login})\n"
        else
          puts "new account (#{un.login})\n"
        end
      end

      if un.new_record?
        un.save
        if un.new_record?
          puts "#{un.login} todavía tiene errores, imposible guardar"
          puts un.errors.full_messages
          raise Exception
        end
        User.db_query("UPDATE users SET password = '#{un.password}' WHERE id = #{un.id}")
      end

      if un.new_record?
        puts "#{un.login} todavía tiene errores, imposible guardar"
        puts un.errors.full_messages
        raise Exception
      end
      un.id
    end
  end
end
