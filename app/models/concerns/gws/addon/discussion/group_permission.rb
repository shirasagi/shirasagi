module Gws::Addon::Discussion
  module GroupPermission
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::GroupPermission
  end
end
