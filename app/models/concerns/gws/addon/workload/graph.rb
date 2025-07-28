module Gws::Addon::Workload::Graph
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :color, type: String
    field :graph_state, type: String, default: "show"
    permit_params :color, :graph_state

    validate :validate_color
    validates :graph_state, presence: true
  end

  def bar_color
    red, green, blue = color.scan(/^\#(.{2})(.{2})(.{2})/).first.map { |i| i.to_i(16) }
    "rgb(#{red},#{green},#{blue},0.5)"
  rescue
    nil
  end

  def graph_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def show_graph?
    graph_state == "show"
  end

  def brightness
    str = self.color.sub(/^#/, '').sub(/^(.)(.)(.)$/, '\\1\\1\\2\\2\\3\\3')
    r, g, b = str.scan(/../).map { |c| c.hex }
    ((r * 299) + (g * 587) + (b * 114)).to_f / 1000
  rescue
    nil
  end

  def text_color
    bgb = brightness
    return nil if bgb.blank?

    (255 - bgb > bgb - 0) ? "#ffffff" : "#000000"
  end

  private

  def validate_color
    if color.blank?
      self.color = SS::RandomColor.random_rgb.to_s
      return
    end
    if !color.match?(/\#[0-9a-f]{6}/i)
      errors.add :color, :invalid
    end
  end

  module ClassMethods
    def and_show_graph
      self.where(graph_state: "show")
    end
  end
end
