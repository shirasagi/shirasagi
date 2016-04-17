module Gws::Referenceable
  extend ActiveSupport::Concern

  def reference_model
    self.class.to_s.underscore
  end

  def reference_name
    name
  end
end
