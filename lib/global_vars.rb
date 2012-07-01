module GlobalVars
  VALID_VAR_NAME = /^[a-z0-9_]+$/
  def self.get_var(var)
    raise "Invalid var name '#{var}'" if !(VALID_VAR_NAME =~ var)
    User.db_query("SELECT #{var} FROM global_vars")[0]
  end

  def self.get_all_vars
    User.db_query("SELECT * FROM global_vars")[0]
  end

  def self.update_var(var, new_value)
    raise "Invalid var name '#{var}'" if !(VALID_VAR_NAME =~ var)
    if new_value == "now()"
      escaped_new_value = new_value
    else
      escaped_new_value = User.connection.quote(new_value)
    end
    User.db_query("UPDATE global_vars SET #{var} = #{escaped_new_value}")
  end
end
