module Uploader::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^uploader\//) }
  end

  class File
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    # include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "uploader/file") }

    before_validation :set_default_state_and_released

    # upload folder only allows `public`
    validates :state, presence: true, inclusion: { in: %w(public), allow_blank: true }

    private

      def set_default_state_and_released
        return if self.persisted?

        self.state = 'public'
        self.released = Time.zone.now
      end
  end
end
