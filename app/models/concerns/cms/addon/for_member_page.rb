module Cms::Addon
  module ForMemberPage
    extend ActiveSupport::Concern
    extend SS::Addon

    def for_member_enabled?
      !!parent.try(:for_member_enabled?)
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
