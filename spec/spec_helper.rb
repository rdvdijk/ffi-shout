# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.report_with_single_file = true
    config.single_report_path = "coverage/lcov.info"
  end

  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov.start { add_filter "/spec/" }
end

require "shout"

require_relative "lib/custom_matchers"
require_relative "lib/fake_http_server"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed

  # Integration specs need a local Icecast server; run them with
  # `rake spec:integration` or `rspec --tag integration`.
  config.filter_run_excluding :integration
  config.filter_run_excluding :slow

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
