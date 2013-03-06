class RemoveSkinTextureTables < ActiveRecord::Migration
  def up
    User.db_query("DROP TABLE skin_textures")
    User.db_query("DROP TABLE textures")
    User.db_query("ALTER TABLE skins DROP COLUMN type")
    User.db_query("ALTER TABLE skins DROP COLUMN intelliskin_header")
    User.db_query("ALTER TABLE skins DROP COLUMN intelliskin_favicon")
    User.db_query("ALTER TABLE skins ADD COLUMN skin_variables text")
  end

  def down
  end
end
