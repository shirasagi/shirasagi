class Opendata::Graph::Bar::Csv
  attr_accessor :resource
  attr_accessor :labels
  attr_accessor :headers
  attr_accessor :datasets

  def initialize(resource)
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

  def extract_datasets
    @datasets = []
    @headers = @csv_lines.first.dup
    @headers.shift

    @csv_columns.each_with_index do |column, i|
      if i == 0
        @labels = column.dup
        @labels.shift
      else
        data = column.dup
        label = data.shift
        @datasets << {
          label: label,
          data: format_data(data)
        }
      end
    end
  end

  def format_data(column)
    column.map { |v| v.gsub(",", "").to_f }
  end
end
