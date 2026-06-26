class Cms::Column::Headline < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  HEADLINE_LEVELS = %w(h1 h2 h3 h4 h5 h6).freeze
  MIN_BOUNDARY_LEVELS = %w(h1 h2).freeze
  MAX_BOUNDARY_LEVELS = %w(h3 h4 h5 h6).freeze
  LEGACY_MIN_HEADLINE_LEVEL = 'h1'.freeze
  LEGACY_MAX_HEADLINE_LEVEL = 'h4'.freeze

  field :min_headline_level, type: String
  field :max_headline_level, type: String
  field :enable_anchor, type: String

  permit_params :min_headline_level, :max_headline_level, :enable_anchor

  validates :min_headline_level, inclusion: { in: MIN_BOUNDARY_LEVELS, allow_blank: true }
  validates :max_headline_level, inclusion: { in: MAX_BOUNDARY_LEVELS, allow_blank: true }
  validates :enable_anchor, inclusion: { in: %w(enabled disabled), allow_blank: true }

  after_initialize :apply_new_column_defaults, if: :new_record?

  def headline_list
    min = effective_min_headline_level
    max = effective_max_headline_level
    min_idx = HEADLINE_LEVELS.index(min) || 0
    max_idx = HEADLINE_LEVELS.index(max) || (HEADLINE_LEVELS.size - 1)
    HEADLINE_LEVELS[min_idx..max_idx].index_by(&:to_sym)
  end

  def min_headline_level_options
    MIN_BOUNDARY_LEVELS.map { |v| [v, v] }
  end

  def max_headline_level_options
    MAX_BOUNDARY_LEVELS.map { |v| [v, v] }
  end

  def effective_min_headline_level
    min_headline_level.presence || LEGACY_MIN_HEADLINE_LEVEL
  end

  def effective_max_headline_level
    max_headline_level.presence || LEGACY_MAX_HEADLINE_LEVEL
  end

  def enable_anchor_options
    %w(disabled enabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def anchor_enabled?
    enable_anchor == 'enabled'
  end

  def form_options(type = nil)
    if type == :head
      options = {}
      options
    else
      super()
    end
  end

  def syntax_check_enabled?
    true
  end

  def link_check_enabled?
    true
  end

  private

  def apply_new_column_defaults
    self.min_headline_level ||= 'h2'
    self.max_headline_level ||= 'h4'
  end
end
