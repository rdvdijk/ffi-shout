if RUBY_DESCRIPTION =~ /\Aruby 3.4/
  require 'simplecov'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.report_with_single_file = true
    config.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter

  SimpleCov.start do
    add_filter '/spec/'
  end
end

require 'pry'
require 'shout'

$LOAD_PATH.unshift(File.expand_path('../../spec', __FILE__))
require 'lib/setter_getter'
require 'lib/custom_matchers'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
