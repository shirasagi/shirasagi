module Cms::CsvImportBase
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:required_headers) { [] }
  end

  module ClassMethods
    def valid_csv?(file)
      no = 0
      each_csv(file) do |row|
        no += 1

        if !required_headers.all? { |h| row.headers.include?(h) }
          return false
        end

        # check csv record up to 100
        break if no >= 100
      end

      true
    rescue => e
      false
    ensure
      file.rewind
    end

    def each_csv(file, &block)
      io = file.to_io
      if utf8_file?(io)
        io.seek(3)
        io.set_encoding('UTF-8')
      else
        io.set_encoding('SJIS:UTF-8')
      end

      csv = ::CSV.new(io, { headers: true })
      csv.each(&block)
    ensure
      io.set_encoding("ASCII-8BIT")
    end

    private

    def utf8_file?(file)
      file.rewind
      bom = file.read(3)
      file.rewind

      bom.force_encoding("UTF-8")
      ::SS::Csv::UTF8_BOM == bom
    end
  end

  class DSL
    def initialize(options)
      @context = options[:context] || self
      @model = options[:model] || self
      @columns = []
    end

    attr_reader :context, :model, :columns

    def import(&block)
      @context.instance_exec(self, &block)
    end

    def simple_column(key, options = {}, &block)
      options = options.dup
      options[:key] = key.to_s
      options[:name] ||= @model.t(key) if key.is_a?(Symbol)
      options[:callback] = block if block_given?

      @columns << options
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
      options[:callback] = block if block_given?

      @form[:columns] << options
    end
  end

  class CSV
    def initialize(dsl)
      @dsl = dsl
    end

    def self.import(options, &block)
      dsl = DSL.new(options)
      dsl.import(&block)
      new(dsl)
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
            column = item.form.columns.where(name: column_name).first
            next if column.blank?

            column_config = @form_config[:columns].find { |column_config| column_config[:name] == column_name }
            next if column_config.blank?

            values = columns.map { |heads, value| [ heads[2], value ] }
            @dsl.context.instance_exec(row, item, @form, column, values, &column_config[:callback])
          end
        end

        item.column_values = column_values
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
      return if @item.form.blank?
      return if @item.form.name != form_name

      form_config = @dsl.columns.find { |config| config[:name] == form_name }
      return if form_config.blank?

      @form = @item.form
      @form_config = form_config

      yield
    ensure
      @form = nil
      @form_config = nil
    end
  end
end
