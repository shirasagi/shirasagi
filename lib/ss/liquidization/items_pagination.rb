class SS::Liquidization::ItemsPagination < Liquid::Tag
  def initialize(tag_name, markup, parse_context)
    super

    markup = markup.to_s.strip if markup.present?
    @variable_name = markup.to_sym if markup.present?
  end

  def render(context)
    items = context.registers[@variable_name || :items]
    return '' unless items
    return '' unless items.try(:current_page)

    view_context = context.registers[:view_context]
    return '' unless view_context
    return '' unless view_context.respond_to?(:paginate)

    view_context.paginate(items)
  rescue => e
    # Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    Rails.logger.warn { "#{e.class} (#{e.message})" }
    ''
  end
end
