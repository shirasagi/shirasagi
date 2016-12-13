module Jmaxml::Addon::Action::PublishPage
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :publish_to, class_name: "Cms::Node"
    field :publish_state, type: String
    embeds_ids :categories, class_name: "Cms::Node"
    permit_params :publish_to_id, :publish_state
    permit_params category_ids: []
  end

  def publish_state_options
    %w(draft public).map { |v| [ I18n.t("views.options.state.#{v}"), v ] }
  end
end
