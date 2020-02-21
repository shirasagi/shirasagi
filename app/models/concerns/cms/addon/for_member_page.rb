module Cms::Addon
  module ForMemberPage
    extend ActiveSupport::Concern
    extend SS::Addon

    def for_member_enabled?
      return false if parent.blank?

      parent_node = parent.becomes_with_route
      return false if parent_node.blank? || !parent_node.respond_to?(:for_member_enabled?)

      parent_node.for_member_enabled?
    end

    def for_member_disabled?
      !for_member_enabled?
    end

    def serve_static_file?
      return false if for_member_enabled?
      super
    end
  end
end
