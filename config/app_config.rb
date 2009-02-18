require 'ostruct'
require 'yaml'

LINUX = 0
WINDOWS = 1

# load custom config
mode = File.exists?("#{RAILS_ROOT}/mode") ? File.open("#{RAILS_ROOT}/mode").read.strip : 'doll2'
mode = 'test' if RAILS_ENV == 'test'
nconfig = OpenStruct.new(YAML::load(ERB.new((IO.read("#{RAILS_ROOT}/config/app.yml"))).result))
env_config = nconfig.send(mode)
::App = OpenStruct.new(env_config)

module AppR
  def self.ondisk_svn_version
    File.exists?("#{RAILS_ROOT}/version") ? File.open("#{RAILS_ROOT}/version").read.strip : 'HEAD'
  end
end