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
