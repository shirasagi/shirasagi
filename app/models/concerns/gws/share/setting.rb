module Gws::Share::Setting
  extend ActiveSupport::Concern
  extend Gws::Setting

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Share::Category.allowed?(action, user, opts)
      #super
      false
    end
  end
end
