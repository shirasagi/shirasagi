class SS::Csv
  UTF8_BOM = "\uFEFF".freeze

  class BaseExporter
    include Enumerable

    def initialize(criteria, options)
      @criteria = criteria.is_a?(Mongoid::Criteria) ? criteria.all.dup : criteria.dup
      @encoding = options[:encoding].presence || "Shift_JIS"
      @cur_site = options[:cur_site]
      @cur_user = options[:cur_user]
      @cur_node = options[:cur_node]
      @model_class = options[:model] || @criteria.klass
      @columns = []
      @context = self
    end

    attr_reader :cur_site, :cur_user, :encoding, :columns

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
      terms = @columns.map do |column|
        head_proc = column[:head]
        if head_proc.blank?
          @model_class.t column[:id]
        else
          @context.instance_exec(&head_proc)
        end
      end

      terms.to_csv
    end

    def _draw_data(item)
      terms = @columns.map do |column|
        body_proc = column[:body]
        if body_proc.present?
          next @context.instance_exec(item, &body_proc)
        end

        type = column[:type]
        case type
        when :label
          next item.label(column[:id])
        when :time
          value = item.try(column[:id])
          if value && value.respond_to?(:strftime)
            next I18n.l(value, format: :picker)
          else
            next nil
          end
        when :date
          value = item.try(column[:id])
          if value && value.respond_to?(:to_date)
            next I18n.l(value.to_date, format: :picker)
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
        I18n.l(value, format: :picker)
      else
        value.to_s
      end
    end
  end

  class ShiftJisExporter < BaseExporter
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

  class UTF8Exporter < BaseExporter
    def draw_header
      UTF8_BOM + _draw_header
    end

    alias draw_data _draw_data
  end

  class DSLExporter
    def initialize(options)
      @context = options[:context] || self
      @columns = []
    end

    attr_reader :context

    def draw(&block)
      @context.instance_exec(self, &block)
    end

    def column(id, options = {}, &block)
      id = id.to_s.to_sym
      @column = @columns.find { |c| c[:id] == id }
      if @column.present?
        @column.merge!(options)
      else
        @column = { id: id }.merge(options)
        @columns << @column
      end
      instance_exec(&block) if block
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
        klass = UTF8Exporter
      else
        klass = ShiftJisExporter
      end

      ret = klass.new(criteria, options)
      ret.instance_variable_set(:@context, @context)
      ret.instance_variable_set(:@columns, @columns)
      ret
    end
  end

  class DSLImporter
    def initialize(options)
      @context = options[:context] || self
      @model = options[:model] || self
      @columns = []
    end

    attr_reader :context, :model, :columns

    def draw(&block)
      @context.instance_exec(self, &block)
    end

    def simple_column(key, options = {}, &block)
      options = options.dup
      options[:key] = key.to_s
      options[:name] ||= @model.t(key) if key.is_a?(Symbol)
      options[:callback] = block if block

      @columns << options
    end

    def label_column(key, options = {}, &block)
      simple_column key do |row, item, head, value|
        options = item.send("#{key}_options")
        private_options = item.send("#{key}_private_options") if item.respond_to?("#{key}_private_options")
        item.send("#{key}=", CsvImporter.from_label(value, options, private_options || {}))
      end
    end

    def form(name, options = {})
      options = options.dup
      options[:name] = name
      options[:columns] = []

      @form = options
      @columns << @form

      yield self
    ensure
      @form = nil
    end

    def column(name, options = {}, &block)
      options = options.dup
      options[:name] = name
      options[:callback] = block if block

      @form[:columns] << options
    end

    def create(options = {})
      CsvImporter.new(self, options)
    end
  end

  class CsvImporter
    class << self
      def from_label(value, main_options, *other_options_array)
        ret = main_options.find { |v, _k, _options| v == value }
        return ret[1] if ret # found option value in main options

        return if other_options_array.blank?

        other_options_array.each do |other_options|
          next if other_options.blank?

          ret = other_options.find { |v, _k, _options| v == value }
          break if ret.present?
        end

        ret[1] if ret # found option value in other options
      end

      def to_array(value, delim: "\n")
        value.to_s.split(delim).map(&:strip)
      end
    end

    def initialize(dsl, options)
      @dsl = dsl
      @options = options
    end

    def import_row(row, item)
      @row = row
      @item = item

      head_value_array = row.headers.map { |h| [ h.split("/"), row[h].try(:strip) ] }

      head_value_array.slice_when { |lhs, rhs| lhs.first.first != rhs.first.first }.each do |chunk|
        heads, value = chunk.first

        if chunk.length == 1
          import_simple_column(row, item, heads.first, value)
          next
        end

        column_values = import_form(heads.first) do
          chunk.slice_when { |lhs, rhs| lhs.first.second != rhs.first.second }.map do |columns|
            _form_name, column_name, _value_name = columns.first.first
            column = @form.columns.where(name: column_name).first
            next if column.blank?

            column_config = @form_config[:columns].find { |column_config| column_config[:name] == column_name }
            next if column_config.blank?

            values = columns.map { |heads, value| [ heads[2], value ] }
            @dsl.context.instance_exec(row, item, @form, column, values, &column_config[:callback])
          end
        end

        item.send("#{@options.dig(:fields, :column_values) || "column_values"}=", column_values)
      end
    end

    private

    def import_simple_column(row, item, head, value)
      config = @dsl.columns.find { |config| config[:name] == head }
      return if config.blank?

      if config[:callback]
        @dsl.context.instance_exec(row, item, head, value, &config[:callback])
      else
        item.send("#{config[:key]}=", value)
      end
    end

    def import_form(form_name)
      form = @item.send(@options.dig(:fields, :form) || "form")
      return if form.blank?
      return if form.name != form_name

      form_config = @dsl.columns.find { |config| config[:name] == form_name }
      return if form_config.blank?

      @form = form
      @form_config = form_config

      yield
    ensure
      @form = nil
      @form_config = nil
    end
  end

  class << self
    def draw(type, options = {}, &block)
      if type == :export
        ret = DSLExporter.new(options)
      else
        ret = DSLImporter.new(options)
      end
      ret.draw(&block) if block
      ret
    end
  end
end
