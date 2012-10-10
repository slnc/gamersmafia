class AdminPermissionSkills < ActiveRecord::Migration
  def up
    %w(eleazar kps sinsa unk).each do |login|
      User.find_by_login(login).users_skills.create(:role => "Capo")
    end

    %w(kps).each do |login|
      User.find_by_login(login).users_skills.create(:role => "BazarManager")
    end

    execute "ALTER TABLE users DROP COLUMN admin_permissions;"
  end

  def down
  end
end
