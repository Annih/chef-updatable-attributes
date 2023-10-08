require 'rspec/core/rake_task'
require 'cookstyle'
require 'rubocop/rake_task'

::RuboCop::RakeTask.new(:cookstyle) { |t| t.options << '--display-cop-names' }
::RSpec::Core::RakeTask.new(:rspec) { |t| t.rspec_opts = '--format documentation' }

task default: %i(cookstyle rspec)
