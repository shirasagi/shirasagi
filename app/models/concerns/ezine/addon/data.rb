module Ezine::Addon
  module Data
    extend ActiveSupport::Concern
    extend SS::Addon

    attr_accessor :in_data

    included do
      embeds_many :data, class_name: "Ezine::Entry::Data"

      after_initialize :set_in_data
      before_validation :set_data, if: ->{ in_data }
      validate :validate_data, if: ->{ in_data }
    end

    public
      def set_in_data
        return if in_data
        self.in_data = {}
        data.each { |data| self.in_data["#{data.column_id}"] = data.value }
      end

      def set_data
        self.data = []
        in_data.each do |key, value|
          next if value.nil?
          if value.kind_of?(Hash)
            values = value.values
            value  = value.map {|k, v| v}.join("\n")
          else
            values = [value.to_s]
            value  = value.to_s
          end
          self.data << Ezine::Entry::Data.new(column_id: key.to_i, value: value, values: values)
        end
      end

      def validate_data
        columns = Ezine::Column.where(node_id: self.node_id, state: "public").order_by(order: 1)
        columns.each do |column|
          if column.required?
            required_data = data.select { |d| column.id == d.column_id }.shift
            if required_data.blank? || required_data.value.blank?
              errors.add :base, "#{column.name}#{I18n.t('errors.messages.blank')}"
            end
          end
        end
      end
  end
end
