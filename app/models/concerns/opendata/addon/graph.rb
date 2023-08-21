module Opendata::Addon::Graph
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :preview_graph_state, type: String, default: "disabled"
    field :preview_graph_types, type: Array, default: []

    permit_params :preview_graph_state
    permit_params preview_graph_types: []

    validate :validate_preview_graph_types, if: ->{ preview_graph_types.present? }
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
    when "bar"
      ::Opendata::Graph::Bar.new(type, self)
    when "line"
      ::Opendata::Graph::Bar.new(type, self)
    when "pie"
      ::Opendata::Graph::Pie.new(type, self)
    end
  end

  private

  def validate_preview_graph_types
    self.preview_graph_types = preview_graph_types.select { |type| I18n.t("opendata.graph_types")[type.to_sym] }
  end
end
