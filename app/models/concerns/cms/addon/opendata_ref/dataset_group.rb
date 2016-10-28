module Cms::Addon::OpendataRef::DatasetGroup
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :opendata_dataset_groups, class_name: "Opendata::DatasetGroup", metadata: { on_copy: :clear }
    permit_params opendata_dataset_group_ids: []
  end
end
