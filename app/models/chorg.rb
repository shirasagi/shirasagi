module Chorg

  class Current < ActiveSupport::CurrentAttributes
    attribute :context
  end

  module_function

  def new_current_context(**options)
    Current.context = OpenStruct.new(options)
  end

  def clear_current_context
    # Current.context = nil
    Current.clear_all
  end

  def current_context
    Current.context
  end
end
