module Opendata::AllowableAny
  extend ActiveSupport::Concern

  def allowed?(action, user, opts = {})
    true
  end

  module ClassMethods
    def allowed?(action, user, opts = {})
      true
    end

    def allow(action, user, opts = {})
      true
    end
  end
end
