class SS::Csv
  UTF8_BOM = "\uFEFF".freeze

  class Base
    include Enumerable

    def initialize(criteria, options)
      @criteria = criteria.is_a?(Mongoid::Criteria) ? criteria.dup : criteria.all.dup
      @encoding = options[:encoding].presence || "Shift_JIS"
      @cur_site = options[:cur_site]
      @cur_user = options[:cur_user]
      @cur_node = options[:cur_node]
      @columns = []
    end

    attr_reader :cur_site, :cur_user
    attr_reader :encoding, :columns

    def each
      yield draw_header
      @criteria.each do |item|
        item = item.becomes_with_route if item.respond_to?(:becomes_with_route)
        item.cur_site = @cur_site if item.respond_to?(:cur_site=)
        item.cur_user = @cur_user if item.respond_to?(:cur_user=)
        item.cur_node = @cur_node if item.respond_to?(:cur_node=)
        yield draw_data(item)
      end
    end

    def content_type
      "text/csv; charset=#{@encoding}"
    end

    private

    def _draw_header
      klass = @criteria.klass

      terms = @columns.map do |column|
        head_proc = column[:head]
        if head_proc.blank?
          klass.t column[:id]
        else
          head_proc.call
        end
      end

      terms.to_csv
    end

    def _draw_data(item)
      # klass = @criteria.klass

      terms = @columns.map do |column|
        body_proc = column[:body]
        if body_proc.present?
          next body_proc.call(item)
        end

        type = column[:type]
        case type
        when :label
          next item.label(column[:id])
        when :time
          value = item.try(column[:id])
          if value && value.respond_to?(:strftime)
            next I18n.l(value, format: :short)
          else
            next nil
          end
        when :date
          value = item.try(column[:id])
          if value && value.respond_to?(:to_date)
            next I18n.l(value.to_date, format: :short)
          else
            next nil
          end
        end

        escape_value(item.try(column[:id]))
      end

      terms.to_csv
    end

    def escape_value(value)
      return nil if value.blank?

      if value.respond_to?(:strftime)
        I18n.l(value, format: :short)
      else
        value.to_s
      end
    end
  end

  class ShiftJis < Base
    def draw_header
      encode_sjis(_draw_header)
    end

    def draw_data(item)
      encode_sjis(_draw_data(item))
    end

    def encode_sjis(str)
      return str if str.blank?
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end
  end

  class UTF8 < Base
    def draw_header
      UTF8_BOM + _draw_header
    end

    alias draw_data _draw_data
  end

  def initialize
    @columns = []
  end

  class << self
    def draw(&block)
      ret = new
      ret.draw(&block)
      ret
    end
  end

  def draw(&block)
    instance_exec(&block)
  end

  def column(id, options = {}, &block)
    @column = { id: id }.merge(options)
    @columns << @column
    instance_exec(&block) if block_given?
    @column = nil
  end

  def head(&block)
    @column[:head] = block
  end

  def body(&block)
    @column[:body] = block
  end

  def enum(criteria, options = {})
    encoding = options[:encoding]
    if encoding && encoding.casecmp("UTF-8") == 0
      klass = UTF8
    else
      klass = ShiftJis
    end

    ret = klass.new(criteria, options)
    ret.instance_variable_set(:@columns, @columns)
    ret
  end
end
