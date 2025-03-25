# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# Set up Rubocop tasks
require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = [
    '--autocorrect-all',
    '--cache=true',
    '--display-cop-names',
    '--display-time',
    '--parallel'
  ]
end

task default: %i[spec rubocop]
