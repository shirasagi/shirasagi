class Opendata::Graph::Base
  attr_reader :csv_lines, :csv_columns, :type, :resource, :labels, :headers, :datasets

  def initialize(type, resource)
    @type = type
    @resource = resource

    extract_csv_lines
    extract_csv_columns
    extract_datasets
  end

  def extract_csv_lines
    @csv_lines = []
    SS::Csv.foreach_row(resource.file, headers: false) do |line|
      if line.select(&:present?).present?
        @csv_lines << line
      end
    end
  end

  def extract_csv_columns
    @csv_columns = []
    @csv_lines.each do |line|
      line.each_with_index do |v, i|
        @csv_columns[i] ||= []
        @csv_columns[i] << v
      end
    end
  end

  def total_column1?
    @total_column1 ||= begin
     # check column1 is total column
      columns_total = []
      @csv_columns.each do |column|
        columns_total << column[1..column.size].sum(&:to_f)
      end
      column1, other = columns_total.partition.with_index { |_, i| i == 1 }.map(&:sum)
      (column1 == other)
    end
  end

  def extract_datasets
    @datasets = []
    @headers = []
  end

  def format_values(values)
    values.map { |value| format_value(value) }
  end

  def format_value(value)
    return "-" if value.blank?
    return value if value !~ /^(-)?((\d)+,)?((\d)+\.)?+(\d)+$/

    value = value.delete(",")
    value = value.to_f.to_s
    value =~ /\.0$/ ? value.to_i : value.to_f
  end
end
