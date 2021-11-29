class Cms::Column::SelectPage < Cms::Column::Base
  field :place_holder, type: String
  embeds_ids :nodes, class_name: "Cms::Node"
  permit_params node_ids: []
end
