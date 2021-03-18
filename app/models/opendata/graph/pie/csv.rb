class Opendata::Graph::Pie::Csv
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
    @headers = @csv_columns.first.dup
    @headers.shift

    skip_first = true
    @csv_lines.each_with_index do |line, i|
      if i == 0
        @labels = line.dup
        @labels.shift

        if skip_first
          @labels.shift
        end
      else
        data = line.dup
        label = data.shift

        if skip_first
          data.shift
        end
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
