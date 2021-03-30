class Opendata::Graph::Base
  attr_reader :csv_lines
  attr_reader :csv_columns

  attr_reader :type
  attr_reader :resource
  attr_reader :labels
  attr_reader :headers
  attr_reader :datasets

  def initialize(type, resource)
    @type = type
    @resource = resource

    extract_csv_lines
    extract_csv_columns
    extract_datasets
  end

  def extract_csv_lines
    encoding = ::NKF.guess(Fs.read(@resource.file.path))
    if encoding.name.downcase =~ /shift_jis|windows/
      encoding = "cp932"
    end

    csv_lines = ::CSV.open(resource.file.path, encoding: "#{encoding}:UTF-8").to_a
    csv_lines = csv_lines.map do |line|
      if line.select { |v| v.present? }.present?
        line
      else
        nil
      end
    end.compact

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
        columns_total << column[1..column.size].map(&:to_f).sum
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
    return data if data !~ /^(\-)?((\d)+\,)?((\d)+\.)?+(\d)+$/

    data = data.gsub(",", "")
    data = data.to_f.to_s
    data =~ /\.0$/ ? data.to_i : data.to_f
  end
end
