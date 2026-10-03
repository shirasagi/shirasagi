class Cms::Column::Toc < Cms::Column::Base
  HEADLINE_LEVELS = Cms::Column::Headline::HEADLINE_LEVELS

  field :min_headline_level, type: String
  field :max_headline_level, type: String

  permit_params :min_headline_level, :max_headline_level

  validates :min_headline_level, inclusion: { in: HEADLINE_LEVELS, allow_blank: true }
  validates :max_headline_level, inclusion: { in: HEADLINE_LEVELS, allow_blank: true }

  def headline_level_options
    HEADLINE_LEVELS.map { |v| [v, v] }
  end

  def effective_min_headline_level
    min_headline_level.presence || HEADLINE_LEVELS.first
  end

  def effective_max_headline_level
    max_headline_level.presence || HEADLINE_LEVELS.last
  end

  # Returns the headline levels (e.g. %w(h2 h3 h4)) that should be picked up by the
  # table of contents. Used to filter which headings appear in the generated list.
  def target_levels
    min_idx = HEADLINE_LEVELS.index(effective_min_headline_level) || 0
    max_idx = HEADLINE_LEVELS.index(effective_max_headline_level) || (HEADLINE_LEVELS.size - 1)
    HEADLINE_LEVELS[min_idx..max_idx]
  end
end
