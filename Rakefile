# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  desc "Run the integration specs (needs a local Icecast server, see README)"
  RSpec::Core::RakeTask.new(:integration) do |task|
    task.pattern = "spec/integration/**/*_spec.rb"
    task.rspec_opts = "--tag integration"
  end
end

RuboCop::RakeTask.new

task default: %i[spec rubocop]
