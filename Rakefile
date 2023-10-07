require 'rspec/core/rake_task'
require 'foodcritic'
require 'rubocop/rake_task'

::FoodCritic::Rake::LintTask.new
::RuboCop::RakeTask.new
::RSpec::Core::RakeTask.new(:rspec) { |t| t.rspec_opts = '--format documentation' }

task default: %i[rubocop foodcritic rspec]
