# frozen_string_literal: true

module SetterGetter
  def has_getter?(shout, flag)
    shout.respond_to?(:"shout_get_#{flag}")
  end

  def has_setter?(shout, flag)
    shout.respond_to?(:"shout_set_#{flag}")
  end

  def sets_value?(shout, flag)
    shout.public_send(:"shout_set_#{flag}", @shout_pointer, @value) == return_value
  end

  def return_value
    defined?(@return) ? @return : 0
  end

  def has_value?(shout, flag)
    if @value.is_a?(Float)
      actual = actual_value(shout, flag)
      (actual - @value).abs < 0.0001
    elsif @value
      actual_value(shout, flag) == @value
    else
      true
    end
  end

  def actual_value(shout, flag)
    shout.public_send(:"shout_get_#{flag}", @shout_pointer)
  end
end
