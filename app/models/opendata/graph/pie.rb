class Opendata::Graph::Pie < Opendata::Graph::Base
  def extract_datasets
    @datasets = []
    @headers = @csv_columns.first.dup
    @headers.shift

    @csv_lines.each_with_index do |line, i|
      if i == 0
        @labels = line.dup
        @labels.shift
        @labels.shift if total_column1?
      else
        values = line.dup
        label = values.shift
        values = format_values(values)
        values.shift if total_column1?
        @datasets << { label: label, data: values }
      end
    end
  end
end
