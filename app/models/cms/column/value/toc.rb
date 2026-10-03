class Cms::Column::Value::Toc < Cms::Column::Value::Base
  liquidize do
    export as: :headlines do
      collect_headlines.map do |hl|
        { "anchor" => hl.resolved_anchor, "text" => headline_text(hl) }
      end
    end
  end

  def history_summary
    Cms::Column::Toc.model_name.human
  end

  private

  # Collects the Headline values of the same page (ordered by +order+) whose column has
  # the anchor feature enabled and whose level falls within the toc's target range.
  # The same +resolved_anchor+ used by each headline's id output is reused here so the
  # generated href="#..." always matches the rendered id.
  def collect_headlines
    return [] if _parent.blank?

    levels = column.respond_to?(:target_levels) ? column.target_levels : nil

    headlines = _parent.column_values.select { |v| v.is_a?(Cms::Column::Value::Headline) }
    headlines = headlines.select { |v| v.head.present? && v.text.present? }
    headlines = headlines.select { |v| v.column&.try(:anchor_enabled?) }
    headlines = headlines.select { |v| levels.include?(v.head) } if levels
    headlines.sort_by { |v| [v.order.to_i, v.id.to_s] }
  end

  def headline_text(headline)
    ApplicationController.helpers.strip_tags(headline.text).to_s.strip
  end

  def validate_value
    # The table of contents has no editor-entered value, so there is nothing to validate.
  end

  def to_default_html
    headlines = collect_headlines
    return '' if headlines.blank?

    helpers = ApplicationController.helpers
    items = headlines.filter_map do |hl|
      text = headline_text(hl)
      next if text.blank?

      helpers.content_tag(:li, helpers.link_to(text, "##{hl.resolved_anchor}"))
    end
    return '' if items.blank?

    helpers.content_tag(:nav, helpers.content_tag(:ul, helpers.safe_join(items)), class: "ss-toc")
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.headlines.size > 0 %})
      h << %(  <nav class="ss-toc">)
      h << %(    <ul>)
      h << %(      {% for headline in value.headlines %})
      h << '      <li><a href="#{{ headline.anchor }}">{{ headline.text }}</a></li>'
      h << %(      {% endfor %})
      h << %(    </ul>)
      h << %(  </nav>)
      h << %({% endif %})
      h.join("\n")
    end
  end
end
