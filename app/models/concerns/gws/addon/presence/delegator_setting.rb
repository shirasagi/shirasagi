module Gws::Addon::Presence::DelegatorSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :presence_editable_titles, class_name: 'Gws::UserTitle'
    permit_params presence_editable_title_ids: []
  end
end
