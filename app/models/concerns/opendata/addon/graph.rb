module Opendata::Addon::Graph
  extend SS::Addon
  extend ActiveSupport::Concern

  AVAILABLE_PREVIEW_GRAPH_TYPES = I18n.t("opendata.graph_types").keys.map(&:to_s)

  included do
    field :preview_graph_state, type: String, default: "disabled"
    field :preview_graph_types, type: Array, default: []

    permit_params :preview_graph_state
    permit_params preview_graph_types: []

    validates :preview_graph_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :preview_graph_types, inclusion: { in: AVAILABLE_PREVIEW_GRAPH_TYPES, allow_blank: true }
  end

  def preview_graph_state_options
    %w(enabled disabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end

  def preview_graph_enabled?
    preview_graph_state == "enabled" && preview_graph_types.present?
  end

  def extract_preview_graph(type)
    return nil unless preview_graph_enabled?

    case type
    when "line"
      ::Opendata::Graph::Bar.new(type, self)
    when "pie"
      ::Opendata::Graph::Pie.new(type, self)
    else # "bar"
      ::Opendata::Graph::Bar.new(type, self)
    end
  end
end
