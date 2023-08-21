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
    csv_lines = []
    SS::Csv.foreach_row(resource.file, headers: false) do |line|
      if line.select(&:present?).present?
        csv_lines << line
      end
    end

    @csv_lines = []
    csv_lines.each do |line|
      @csv_lines << line.map { |v| format_data(v) }
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

  def format_data(data)
    return "-" if data.blank?
    return data if data !~ /^(-)?((\d)+,)?((\d)+\.)?+(\d)+$/

    data = data.delete(",")
    data = data.to_f.to_s
    data =~ /\.0$/ ? data.to_i : data.to_f
  end
end
