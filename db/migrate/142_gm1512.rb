class Gm1512 < ActiveRecord::Migration
  def self.up
    execute "UPDATE products SET cls = 'SoldUserAvatar' WHERE cls = 'SoldCustomAvatar';"
  end

  def self.down
  end
end
