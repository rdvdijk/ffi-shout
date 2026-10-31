require_relative 'setter_getter'

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
    set_value(actual, expected) &&
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

# Validate delegation to shout.
RSpec::Matchers.define :delegate do |from|
  include SetterGetter

  chain :to do |target|
    @target = target
  end

  match do |subject|
    @from = from
    @target ||= from
    has_setter?(Shout, @target) &&
      delegates_setter?(subject) &&
      has_getter?(Shout, @target) &&
      delegates_getter?(subject)
  end

  def delegates_setter?(subject)
    expect(Shout).to receive(:"shout_set_#{@target}").with(subject.shout, anything)
    subject.send(:"#{@from}=", double)
    true
  rescue => e
    false
  end

  def delegates_getter?(subject)
    expect(Shout).to receive(:"shout_get_#{@target}").with(subject.shout)
    subject.send(:"#{@from}")
    true
  rescue => e
    false
  end
end
