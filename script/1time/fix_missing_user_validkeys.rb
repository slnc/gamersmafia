User.db_query("SELECT id FROM users WHERE validkey is null").each do |dbu|
  User.db_query("UPDATE users SET validkey = '#{Digest::MD5.hexdigest(AccountHelper::Utils::random_string(30))}' WHERE id = #{dbu['id']}")
end