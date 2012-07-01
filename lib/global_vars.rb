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
    # TODO(slnc): for performance reason keep track of when we updated a var and
    # don't update it if within a second of the last update.
    raise "Invalid var name '#{var}'" if !(VALID_VAR_NAME =~ var)
    if new_value == "now()"
      escaped_new_value = new_value
    else
      escaped_new_value = User.connection.quote(new_value)
    end
    User.db_query("UPDATE global_vars SET #{var} = #{escaped_new_value}")
  end

  def self.update_clans_updated_on
    last_clan = Clan.find(:first, :order => "updated_on DESC")
    if last_clan
      new_value = last_clan.updated_on
    else
      Rails.logger.warn("No clans found for update_clans_updated_on")
      new_value = Time.now
    end
    self.update_var("clans_updated_on", new_value)
  end
end
