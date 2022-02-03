module Cms::Addon
  module Line::Service::PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model
    include SS::Relation::File
    include Fs::FilePreviewable

    included do
      belongs_to_file :no_image, static_state: "public"
    end

    def state
      "public"
    end

    def file_previewable?(file, user:, member:)
      true
    end

    def interpret_default_location(default_site, &block)
    end
  end
end
