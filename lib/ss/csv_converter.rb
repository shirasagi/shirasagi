class SS::CsvConverter
  class << self
    def enum_csv(criteria, field_names = nil)
      criteria = criteria.all unless criteria.is_a?(Mongoid::Criteria)
      field_names ||= extract_field_names(criteria)

      drawer = SS::Csv.draw(:export) do |d|
        field_names.each do |field_name|
          d.column field_name
        end
      end

      drawer.enum(criteria)
    end

    private

    def extract_field_names(criteria)
      field_names = criteria.klass.fields.keys if criteria.respond_to?(:klass)
      field_names ||=@criteria.fields.keys if criteria.respond_to?(:fields)

      field_names - %w(_id text_index)
    end
  end
end
