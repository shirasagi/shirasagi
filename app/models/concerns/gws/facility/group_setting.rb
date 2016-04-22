module Gws::Facility::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Facility::Item.allowed?(action, user, opts)
      return true if Gws::Facility::Category.allowed?(action, user, opts)
      #super
      false
    end
  end
end
