class FixEmblemsMask < ActiveRecord::Migration
  def up
    User.find_each do |u|
      u.emblems_mask = nil
      u.emblems_mask_or_calculate
    end
  end

  def down
  end
end
