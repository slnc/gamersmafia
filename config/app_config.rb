require 'ostruct'
require 'yaml'

LINUX = 0
WINDOWS = 1

# load custom config
mode = File.exists?("#{RAILS_ROOT}/config/mode") ? File.open("#{RAILS_ROOT}/config/mode").read.strip : 'doll2'
mode = 'test' if RAILS_ENV == 'test'
nconfig = OpenStruct.new(YAML::load(ERB.new((IO.read("#{RAILS_ROOT}/config/app.yml"))).result))
env_config = nconfig.send(mode)
::App = OpenStruct.new(env_config)

module AppR
  def self.ondisk_git_version
    @_cache_v  ||= begin
      v = File.exists?("#{RAILS_ROOT}/REVISION") ? File.open("#{RAILS_ROOT}/REVISION").read.strip[0..6] : 'HEAD'
      # esto es necesario porque en bamboo peta si no
      begin
        ActiveRecord::Base.db_query("UPDATE global_vars set svn_revision = '#{v}'")
      rescue
      end 
v
 end
  end
end
