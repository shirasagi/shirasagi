class Opendata::Graph::Bar < Opendata::Graph::Base
  def extract_datasets
    @datasets = []
    @headers = @csv_lines.first.dup
    @headers.shift

    @csv_columns.each_with_index do |column, i|
      if i == 0
        @labels = column.dup
        @labels.shift
      else
        values = column.dup
        label = values.shift
        values = format_values(values)
        @datasets << { label: label, data: values }
      end
    end
  end
end
