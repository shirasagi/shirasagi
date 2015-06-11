module Cms::Addon
  module GroupPermission
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::GroupPermission

    set_order 600
  end
end
