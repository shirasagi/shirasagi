module Opendata::Addon::Metadata
  module ImporterNotice
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :notice_users, class_name: "Cms::User"

      permit_params notice_user_ids: []
    end
  end
end
