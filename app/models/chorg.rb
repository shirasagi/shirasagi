module Chorg

  module_function

  def new_current_context(**options)
    Thread.current["ss.chorg.context"] = OpenStruct.new(options)
  end

  def clear_current_context
    Thread.current["ss.chorg.context"] = nil
  end

  def current_context
    Thread.current["ss.chorg.context"]
  end
end
