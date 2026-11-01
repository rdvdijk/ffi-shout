# frozen_string_literal: true

require_relative "setter_getter"

# Validate existence of a getter, setter and the default value.
RSpec::Matchers.define :have_flag do |expected|
  include SetterGetter

  chain :for do |shout_pointer|
    @shout_pointer = shout_pointer
  end

  chain :with_value do |value|
    @value = value
  end

  match do |actual|
    has_getter?(actual, expected) &&
      has_setter?(actual, expected) &&
      has_value?(actual, expected)
  end
end

# Validate setting a value.
RSpec::Matchers.define :be_able_to_set do |expected|
  include SetterGetter

  chain :for do |shout_pointer|
    @shout_pointer = shout_pointer
  end

  chain :to do |value|
    @value = value
  end

  chain :and_return do |value|
    @return = value
  end

  match do |actual|
    sets_value?(actual, expected) &&
      has_value?(actual, expected)
  end
end

# Validate getting a value.
RSpec::Matchers.define :have_getter do |expected|
  include SetterGetter

  chain :for do |shout_pointer|
    @shout_pointer = shout_pointer
  end

  chain :with_value do |value|
    @value = value
  end

  match do |actual|
    has_getter?(actual, expected) &&
      has_value?(actual, expected)
  end

  failure_message do |actual|
    if !has_getter?(actual, expected)
      "expected that #{actual} would have a getter for field :#{expected}"
    elsif @value && !has_value?(actual, expected)
      actual_val = actual_value(actual, expected)
      "expected field :#{expected} to have a value of #{@value}, but got #{actual_val}"
    end
  end
end

# Validate that a configuration attribute delegates its reader and writer to
# shout_get_<target> / shout_set_<target>, passing the shout pointer along.
RSpec::Matchers.define :delegate do |from|
  chain :to do |target|
    @target = target
  end

  match do |subject|
    @target ||= from
    @problems = []
    check_setter(subject, from)
    check_getter(subject, from)
    @problems.empty?
  end

  failure_message do |subject|
    "expected #{subject.class} to delegate ##{from} and ##{from}= to " \
      "shout_get_#{@target} / shout_set_#{@target}, but #{@problems.join("; ")}"
  end

  def check_setter(subject, from)
    check(subject, :"shout_set_#{@target}", "##{from}=") do
      subject.public_send(:"#{from}=", "value")
    end
  end

  def check_getter(subject, from)
    check(subject, :"shout_get_#{@target}", "##{from}") do
      subject.public_send(from)
    end
  end

  def check(subject, function, method_name, &block)
    unless Shout::Native.respond_to?(function)
      @problems << "Shout.#{function} does not exist"
      return
    end

    calls = record_calls(function, &block)
    return if calls.any? { |args| args.first.equal?(subject.shout) }

    @problems << "#{method_name} did not call Shout.#{function} with the shout pointer (calls: #{calls.inspect})"
  rescue StandardError => e
    @problems << "#{method_name} raised #{e.class}: #{e.message}"
  end

  # Stubs Shout.<function>, runs the block and returns the argument lists of
  # all calls made to it.
  def record_calls(function)
    calls = []
    allow(Shout::Native).to receive(function) { |*args| calls << args and 0 }
    yield
    calls
  end
end
