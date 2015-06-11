module Cms::Addon
  module GroupPermission
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::GroupPermission
  end
end
