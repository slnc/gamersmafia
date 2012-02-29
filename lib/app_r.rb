module AppR
  REVISION_FILE = "#{Rails.root}/config/REVISION"

  def self.ondisk_git_version
    @_cache_v  ||= begin
      if File.exists?(REVISION_FILE)
        version = File.open(REVISION_FILE).read.strip[0..6]
      else
        version = "HEAD"
      end

      ActiveRecord::Base.db_query(
        "UPDATE global_vars set svn_revision = '#{version}'")
      version
    end
  end
end
