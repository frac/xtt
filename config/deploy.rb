set :stages, %w(staging production)
set :default_stage, 'staging'
require 'capistrano/ext/multistage' rescue 'YOU NEED TO INSTALL THE capistrano-ext GEM'
require 'capistrano/gitflow' rescue 'YOU NEED TO INSTALL THE capistrano-gitflow GEM'


Dir[File.join(File.dirname(__FILE__), '..', 'vendor', 'gems', 'hoptoad_notifier-*')].each do |vendored_notifier|
  $: << File.join(vendored_notifier, 'lib')
end

require 'hoptoad_notifier/capistrano'
