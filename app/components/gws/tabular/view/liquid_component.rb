#frozen_string_literal: true

class Gws::Tabular::View::LiquidComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :cur_space, :cur_form, :cur_view, :items

  TEMPLATE_ALLOWED_TAGS = begin
    # Rails 7.x standards
    # see: https://github.com/rails/rails-html-sanitizer/blob/v1.6.0/lib/rails/html/sanitizer.rb#L79-L122
    tags = %w(a abbr acronym address b big blockquote br cite
              code dd del dfn div dl dt em h1 h2 h3 h4 h5 h6
              hr i img ins kbd li ol p pre samp small span strong
              sub sup time tt ul var)

    # SHIRASAGI standards
    # see: config/initializers/sanitize.rb
    tags += %w(font strike s u table thead tbody tr th td)

    # And tabular supports
    tags += %w(tfoot nav figure details summary)

    Set.new(tags.sort).freeze
  end
  TEMPLATE_ALLOWED_ATTRIBUTES = begin
    # Rails 7.x standards
    # see: https://github.com/rails/rails-html-sanitizer/blob/v1.6.0/lib/rails/html/sanitizer.rb#L125-L139
    attributes = %w(abbr alt cite class datetime height href lang name src title width xml:lang)

    # SHIRASAGI standards excepts style
    # see: config/initializers/sanitize.rb
    attributes += %w(border color face size align valign cellspacing cellpadding colspan rowspan)

    # And tabular supports
    attributes += %w(aria-label data-show-in)

    Set.new(attributes.sort).freeze
  end

  STYLE_ALLOWED_TAGS = Set.new(%w(style)).freeze
  STYLE_ALLOWED_ATTRIBUTES = Set.new(%w(media nonce title)).freeze

  module PathFilter
    def show_url(item)
      view_context = context.registers[:view_context]
      return unless view_context

      cur_site = context.registers[:cur_site]
      cur_space = context.registers[:cur_space]
      cur_form = context.registers[:cur_form]
      cur_view = context.registers[:cur_view]

      item = item.delegatee if item.respond_to?(:delegatee)
      view_context.gws_riken_recycle_board_file_path(
        site: cur_site, space: cur_space, form: cur_form, view: cur_view || '-', id: item)
    end
  end

  module PaginationFilter
    def paginated?(_items)
      items = context.registers[:items]
      items.try(:current_page) != nil
    end

    def total_pages(_items)
      items = context.registers[:items]
      items.try(:total_pages)
    end

    def current_page(_items)
      items = context.registers[:items]
      items.try(:current_page)
    end

    def current_range(current_items)
      items = context.registers[:items]
      current_page = items.try(:current_page)
      return unless current_page

      cur_view = context.registers[:cur_view]
      limit_count = cur_view.try(:limit_count)
      limit_count ||= SS.max_items_per_page

      first = (current_page - 1) * limit_count + 1
      [ first, first + current_items.count - 1 ]
    end

    def next_page(_items)
      items = context.registers[:items]
      items.try(:next_page)
    end

    def prev_page(_items)
      items = context.registers[:items]
      items.try(:prev_page)
    end

    def first_page?(_items)
      items = context.registers[:items]
      items.try(:first_page?)
    end

    def last_page?(_items)
      items = context.registers[:items]
      items.try(:last_page?)
    end

    def out_of_range?(_items)
      items = context.registers[:items]
      items.try(:out_of_range?)
    end

    def limit_value(_items)
      items = context.registers[:items]
      items.try(:limit_value)
    end

    def offset_value(_items)
      items = context.registers[:items]
      items.try(:offset_value)
    end

    def total_count(_items)
      items = context.registers[:items]
      items.count
    end
  end

  def render_template
    source = cur_view.template_html
    return if source.blank?

    template = Liquid::Template.parse(source)
    setup_template(template)

    assigns = { "items" => items.to_a }
    html = template.render(assigns, [ PathFilter, PaginationFilter ])
    return if html.blank?

    view_context.sanitize(html, tags: TEMPLATE_ALLOWED_TAGS, attributes: TEMPLATE_ALLOWED_ATTRIBUTES)
  end

  def render_style
    return if cur_view.template_style.blank?
    view_context.sanitize(cur_view.template_style, tags: STYLE_ALLOWED_TAGS, attributes: STYLE_ALLOWED_ATTRIBUTES)
  end

  private

  def setup_template(template)
    template.registers[:cur_site] = cur_site
    template.registers[:cur_user] = cur_user
    template.registers[:cur_space] = cur_space
    template.registers[:cur_form] = cur_form
    template.registers[:cur_view] = cur_view
    template.registers[:items] = items
    template.registers[:view_context] = view_context
    template
  end
end
