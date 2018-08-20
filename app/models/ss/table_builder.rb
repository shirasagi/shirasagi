class SS::TableBuilder

  class Column
    attr_accessor :th, :td

    def render_th
      @th.call
    end

    def render_td(item)
      @td.call(item)
    end
  end

  def initialize(bind)
    @bind = bind
    @columns = []
  end

  attr_reader :columns

  def build(&block)
    yield(self)
    self
  end

  def column(*args, &block)
    @column = Column.new
    @column_options = args.extract_options!

    yield

    raise "th is required" if @column.th.blank?
    raise "td is required" if @column.td.blank?

    @columns << @column
    @column = nil
  end

  def tap_menu(*args, &block)
    column do
      th ""
      td do |item|
        capture do
          output_buffer << "<div class=\"dropdown\">".html_safe
          output_buffer << "<button class=\"btn bmd-btn-icon dropdown-toggle\" type=\"button\" id=\"ex1\" data-toggle=\"dropdown\" aria-haspopup=\"true\" aria-expanded=\"false\"><i class=\"material-icons\">more_vert</i></button>".html_safe
          output_buffer << "<div class=\"dropdown-menu dropdown-menu-left\" aria-labelledby=\"ex1\">".html_safe
          yield item
          output_buffer << "</div>".html_safe
          output_buffer << "</div>".html_safe
        end
      end
    end
  end

  def column_checkbox
    column(class: "check") do
      th "<input type=\"checkbox\" />".html_safe
      td do |item|
        "<div class=\"checkbox\"><input type=\"checkbox\" name=\"ids[]\" value=\"#{item.id}\" /></div>".html_safe
      end
    end
  end

  def column_updated
    column(class: "datetime") do
      th I18n.t("cms.options.sort.updated_1")
      td do |item|
        if item.respond_to?(:updated)
          item.updated.strftime("%Y/%m/%d %H:%M")
        end
      end
    end
  end

  def th(*args, &block)
    options = args.extract_options!
    options = options.reverse_merge(@column_options)
    if block_given?
      @column.th = proc { capture { content_tag("th", options, &block) } }
    else
      content = args.first
      @column.th = proc { content_tag("th", content, options) }
    end
  end

  def td(*args, &block)
    raise "block is required" if !block_given?
    options = args.extract_options!
    options = options.reverse_merge(@column_options)
    @column.td = proc { |item| capture { content_tag("td", options) { yield item } } }
  end

  def method_missing(name, *args, &block)
    if @bind.receiver.respond_to?(name)
      @bind.receiver.send(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(symbol, include_private)
    @bind.receiver.respond_to?(symbol, include_private) || super
  end
end
