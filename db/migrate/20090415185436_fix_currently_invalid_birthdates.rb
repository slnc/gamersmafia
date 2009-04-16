class FixCurrentlyInvalidBirthdates < ActiveRecord::Migration
  def self.up
    User.db_query("UPDATE users 
                      SET birthday = null 
                    WHERE extract('year' from birthday) < extract('year' from now() - '130 years'::interval) or extract('year' from birthday) > extract('year' from now() - '3 years'::interval)")
  end

  def self.down
  end
end
