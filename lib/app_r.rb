# -*- encoding : utf-8 -*-
module AppR
  REVISION_FILE = "#{Rails.root}/config/REVISION"

  def self.ondisk_git_version
    @_cache_v ||= begin
      all_tags = `git --git-dir=#{Rails.root}/.git --work-tree=#{Rails.root} tag | grep release`.strip.split("\n")
      if all_tags.size == 0
        last_tag = `git --git-dir=#{Rails.root}/.git --work-tree=#{Rails.root} log production --no-merges --pretty=format:"%h" | head -n 1`.strip
      else
        last_tag = all_tags.sort.last
      end

      GlobalVars.update_var("svn_revision", last_tag)
      last_tag.gsub(/[^0-9]/, "")
    end
  end
end
