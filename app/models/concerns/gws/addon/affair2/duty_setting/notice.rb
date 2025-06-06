module Gws::Addon::Affair2
  module DutySetting
    module Notice
      extend ActiveSupport::Concern
      extend SS::Addon

      included do
        embeds_ids :duty_notices, class_name: 'Gws::Affair2::DutyNotice'
        permit_params duty_notice_ids: []
      end
    end
  end
end
