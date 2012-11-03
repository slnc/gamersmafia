class FixStatsCaches < ActiveRecord::Migration
  def up
    `rm #{Rails.root}/tmp/fragment_cache/common/miembros/*/*/contents_stats*`
  end

  def down
  end
end
