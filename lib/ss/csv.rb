class SS::Csv
  UTF8_BOM = "\uFEFF".freeze
  MAX_READ_ROWS = 100

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
      I18n.with_locale(I18n.default_locale) do
        yield draw_header
        @criteria.each do |item|
          item.cur_site = @cur_site if item.respond_to?(:cur_site=)
          item.cur_user = @cur_user if item.respond_to?(:cur_user=)
          item.cur_node = @cur_node if item.respond_to?(:cur_node=)
          yield draw_data(item)
        end
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

    # public #draw_data is required
    def draw_data(item)
      _draw_data(item)
    end
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

    def label_column(key, &block)
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
            _form_name = columns.first.first.shift
            column_name = columns.first.first.join("/")
            column = @form.columns.where(name: column_name).first
            unless column
              _value_name = columns.first.first.pop
              column_name = columns.first.first.join("/")
              column = @form.columns.where(name: column_name).first
            end
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
        setter = "#{config[:key]}="
        item.send(setter, value) if item.respond_to?(setter)
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
      if block
        I18n.with_locale(I18n.default_locale) do
          ret.draw(&block)
        end
      end
      ret
    end

    AUTO_DETECT_ENCODINGS = [ Encoding::SJIS, Encoding::UTF_8 ].freeze

    def detect_encoding(path_or_io_or_ss_file)
      if path_or_io_or_ss_file.respond_to?(:rewind)
        # io like File, ActionDispatch::Http::UploadedFile or Fs::UploadedFile
        return with_keeping_io_position(path_or_io_or_ss_file) { |io| _detect_encoding(io) }
      end

      if path_or_io_or_ss_file.respond_to?(:to_io)
        # ss/file
        return path_or_io_or_ss_file.to_io { |io| _detect_encoding(io) }
      end

      # path
      ::File.open(path_or_io_or_ss_file, "rb") { |io| _detect_encoding(io) }
    end

    def open(path_or_io_or_ss_file, headers: true, &block)
      raise ArgumentError, "block is missing" unless block_given?

      if path_or_io_or_ss_file.respond_to?(:rewind)
        # io like File, ActionDispatch::Http::UploadedFile or Fs::UploadedFile
        with_keeping_io_position(path_or_io_or_ss_file) { |io| _open(io, headers: headers, &block) }
        return
      end

      if path_or_io_or_ss_file.respond_to?(:to_io)
        # ss/file
        path_or_io_or_ss_file.to_io { |io| _open(io, headers: headers, &block) }
        return
      end

      # path
      ::File.open(path_or_io_or_ss_file, "rb") { |io| _open(io, headers: headers, &block) }
    end

    def foreach_row(path_or_io_or_ss_file, headers: true, &block)
      raise ArgumentError, "block is missing" unless block_given?

      SS::Csv.open(path_or_io_or_ss_file, headers: headers) do |csv|
        if block.arity == 2
          csv.each.with_index(&block)
        else
          csv.each(&block)
        end
      end
    end

    def valid_csv?(path_or_io_or_ss_file, headers: true, required_headers: nil, max_rows: nil)
      max_rows ||= SS::Csv::MAX_READ_ROWS

      count = 0
      SS::Csv.foreach_row(path_or_io_or_ss_file, headers: headers) do |row|
        count += 1

        return false if required_headers && required_headers.any? { |h| !row.headers.include?(h) }

        break if count >= max_rows
      end
      count != 0
    rescue => e
      Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      false
    end

    private

    def with_keeping_io_position(io)
      io = io.tempfile if io.is_a?(ActionDispatch::Http::UploadedFile)
      save_pos = io.pos

      yield io
    ensure
      io.pos = save_pos
    end

    def utf8_bom?(bom)
      UTF8_BOM.bytes == bom.bytes
    end

    def _detect_encoding(io)
      bom = io.read(3)
      return Encoding::UTF_8 if utf8_bom?(bom)

      body = bom + io.read(997)

      encoding = AUTO_DETECT_ENCODINGS.find do |encoding|
        byte_count = count_valid_bytes(body.dup, encoding)

        (byte_count * 100 / body.length) > 90
      end

      encoding || Encoding::ASCII_8BIT
    end

    def count_valid_bytes(buff, encoding)
      buff.force_encoding(encoding)

      byte_count = 0
      buff.each_codepoint { |cp| byte_count += cp.chr(encoding).bytes.length }

      byte_count
    rescue ArgumentError
      # invalid byte sequence in ...
      byte_count
    end

    def _open(io, headers:, &block)
      encoding = with_keeping_io_position(io) { _detect_encoding(io) }
      return if encoding == Encoding::ASCII_8BIT

      io.set_encoding(encoding)
      if encoding == Encoding::UTF_8
        # try to skip the BOM
        pos = io.pos
        bom = io.read(3)
        io.pos = pos if !utf8_bom?(bom)
      end

      if io.is_a?(StringIO) && io.pos > 0
        # gem "csv" 内で StringIO#string を呼び出している箇所がある。
        # StringIO#string は BOM 付きの文字列を返すので、うまく動作しない。
        # そこで、BOM無しにしてやる
        source = io.read
        io = StringIO.new(source)
      end

      csv = CSV.new(io, headers: headers)
      yield csv
    end
  end
end
