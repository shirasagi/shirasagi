class Opendata::Graph::PivotCsv
  attr_accessor :resource
  attr_accessor :csv_lines, :csv_columns
  attr_accessor :line_range, :column_range

  attr_accessor :labels
  attr_accessor :datasets

  def initialize(resource)
    @resource = resource

    extact_csv_lines
    extract_csv_columns
    extract_pivot
    extract_lables
    extract_datasets
  end

  def extact_csv_lines
    encoding = ::NKF.guess(Fs.read(@resource.file.path))
    if encoding.name.downcase =~ /shift_jis|windows/
      encoding = "cp932"
    end

    @csv_lines = ::CSV.open(resource.file.path, encoding: "#{encoding}:UTF-8").to_a
    @csv_lines = @csv_lines.map do |line|
      if line.select { |v| v.present? }.present?
        line
      else
        nil
      end
    end.compact
  end

  def extract_csv_columns
    @csv_columns = []
    @csv_lines.each do |line|
      line.each_with_index do |v, i|
        @csv_columns[i] ||= []
        @csv_columns[i] << v
      end
    end
    @csv_columns
  end

  def extract_pivot
    @line_range = nil
    @column_range = nil
    line_first = 0

    @csv_columns.each_with_index do |column, i|
      if @column_range
        pivot_column = column[@column_range]

        if find_index_range(pivot_column)
          @line_range = (line_first..i)
          #puts "#{i}: #{pivot_column}"
        else
          break
        end
      else
        @column_range = find_index_range(column)
        if @column_range
          line_first = i
          @line_range = (line_first..i)
          #puts "index_range found : #{column_range}"
        end
      end
    end
  end

  def extract_lables
    @labels = @csv_columns[@line_range.first - 1]
    return if @labels.blank?

    @labels = @labels[@column_range]
  end

  def extract_datasets
    header_index = @column_range.first - 1
    return if header_index < 0

    @headers = @csv_lines[header_index]
    return if @headers.blank?

    @headers = @headers[@line_range]
    @datasets = @csv_columns[@line_range].map.with_index do |item, i|
      {
        label: @headers[i].presence || "header#{i}",
        data: format_data(item[@column_range])
      }
    end
  end

  def format_data(column)
    column.map { |v| v.gsub(",", "").to_i }
  end

  def find_index_range(array)
    target_range = nil
    array.each_with_index do |_, i|
      left_index = i.dup

      while i < array.size
        if array[i] =~ /^(\-)?((\d)+\,)?((\d)+\.)?+(\d)+$/
          i += 1
        else
          break
        end
      end

      if i - left_index >= 3
        target_range = (left_index..(i - 1))
        break
      end
    end
    target_range
  end
end
