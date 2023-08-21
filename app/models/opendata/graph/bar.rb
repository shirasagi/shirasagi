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
        data = column.dup
        label = data.shift
        @datasets << {
          label: label,
          data: format_data(data)
        }
      end
    end
  end
end
