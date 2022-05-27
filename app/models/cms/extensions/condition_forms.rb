#
# condition_forms: [
#   {
#     form_id: 7,
#     filters: [
#       {
#         column_id: BSON::ObjectId("61adf8e9e2dbd7169f76009a"),
#         condition_kind: 'any_of'
#         condition_values: [ 'foo', 'bar', 'baz' ]
#       },
#       {
#         column_id: BSON::ObjectId("61adf91be2dbd7155d7600cd"),
#         condition_kind: 'start_with'
#         condition_values: [ '430' ]
#       }
#     ]
#   },
#   {
#     form_id: 15,
#     filters: [
#       {
#         column_id: BSON::ObjectId("61adf8e9e2dbd7169f76009a"),
#         condition_kind: 'greater_than_or_equal_to'
#         condition_values: [ 10 ]
#       }
#     ]
#   },
#   {
#     form_id: 18,
#     filters: []
#   }
# ]
#
module Cms::Extensions
  module CollectionFactory
    def self.[](klass)
      Struct.new(:values, keyword_init: true) do
        extend Forwardable
        include Enumerable

        def_delegators :values, :[], :[]=, :length, :size, :each, :sort_by, :count, :find, :find_index, :select, :reject,
          :map, :group_by, :all?, :any?, :each_with_index, :reverse_each, :each_slice, :take, :drop,
          :empty?, :present?, :blank?

        cattr_accessor :model
        self.model = klass

        def to_a
          return if values.blank?
          values.map { |value| value.to_h }
        end

        # Converts an object of this instance into a database friendly value.
        alias_method :mongoize, :to_a

        def to_mongo_query
          return [] if values.blank?
          values.map { |value| value.to_mongo_query }.select(&:present?)
        end

        class << self
          # Get the object as it was stored in the database, and instantiate
          # this custom class from it.
          def demongoize(object)
            return new(values: []) if object.nil?
            new(values: object.map { |value| model.demongoize(value) })
          end

          # Takes any possible object and converts it to how it would be
          # stored in the database.
          def mongoize(object)
            return nil if object.nil?
            case object
            when self
              object.mongoize
            else
              object
            end
          end
        end
      end
    end
  end

  ConditionFormFilter = Struct.new(:column_id, :condition_kind, :condition_values, keyword_init: true) do
    KNOWN_CONDITION_KINDS = %w(any_of none_of start_with end_with).freeze

    def to_h
      { column_id: column_id, condition_kind: condition_kind, condition_values: condition_values }
    end

    # Converts an object of this instance into a database friendly value.
    alias_method :mongoize, :to_h

    def to_mongo_query
      return if condition_kind.blank? || !KNOWN_CONDITION_KINDS.include?(condition_kind) || condition_values.blank?

      value_type = column.try(:value_type)
      return unless value_type

      condition = value_type.build_mongo_query(condition_kind, condition_values)
      return if condition.blank?

      condition[:column_id] = column_id

      { column_values: { "$elemMatch" => condition } }
    end

    def column
      Cms::Column::Base.where(id: column_id).first
    end

    class << self
      # Get the object as it was stored in the database, and instantiate
      # this custom class from it.
      def demongoize(object)
        return nil if object.nil?

        new(
          column_id: object[:column_id] || object["column_id"],
          condition_kind: object[:condition_kind] || object["condition_kind"],
          condition_values: object[:condition_values] || object["condition_values"]
        )
      end

      # Takes any possible object and converts it to how it would be
      # stored in the database.
      def mongoize(object)
        return nil if object.nil?
        case object
        when self
          object.mongoize
        else
          object
        end
      end
    end
  end

  ConditionFormFilters = CollectionFactory[ConditionFormFilter]

  ConditionForm = Struct.new(:form_id, :filters, keyword_init: true) do
    def to_h
      { form_id: form_id, filters: filters.map { |filter| filter.to_h } }
    end

    # Converts an object of this instance into a database friendly value.
    alias_method :mongoize, :to_h

    def to_mongo_query
      return { form_id: form_id } if filters.blank?

      conditions = filters.to_mongo_query
      if conditions.count == 0
        { form_id: form_id }
      elsif conditions.count == 1
        conditions.first.merge(form_id: form_id)
      else
        { form_id: form_id, "$and" => conditions }
      end
    end

    def form
      Cms::Form.where(id: form_id).first
    end

    class << self
      # Get the object as it was stored in the database, and instantiate
      # this custom class from it.
      def demongoize(object)
        return nil if object.nil?

        form_id = object[:form_id] || object["form_id"]
        filters = ConditionFormFilters.demongoize(object[:filters] || object["filters"])

        new(form_id: form_id, filters: filters)
      end

      # Takes any possible object and converts it to how it would be
      # stored in the database.
      def mongoize(object)
        return nil if object.nil?
        case object
        when self
          object.mongoize
        else
          object
        end
      end
    end
  end

  ConditionForms = CollectionFactory[ConditionForm]

  class ConditionForms
    class << self
      # # Get the object as it was stored in the database, and instantiate
      # # this custom class from it.
      # def demongoize(object)
      #   return new_default_instance if object.nil?
      #
      #   if object.is_a?(Hash) && object.key?("form_ids")
      #     return demongoize_from_edit_form(object)
      #   end
      #
      #   new(values: object.map { |value| model.demongoize(value) })
      # end

      # Takes any possible object and converts it to how it would be
      # stored in the database.
      def mongoize(object)
        return nil if object.nil?
        case object
        when self
          object.mongoize
        when Hash
          mongoize_from_edit_form(object)
        else
          object
        end
      end

      private

      def mongoize_from_edit_form(object)
        form_ids = object["form_ids"]
        return nil if form_ids.blank?

        form_ids = form_ids.select(&:numeric?)
        form_ids = form_ids.map(&:to_i)
        return nil if form_ids.blank?

        forms = Cms::Form.all.in(id: form_ids).to_a
        return nil if forms.blank?

        filters = object["filters"]
        forms.map do |form|
          mongoize_filters_from_edit_form(form, filters)
        end
      end

      def mongoize_filters_from_edit_form(form, filter_hashes)
        filters_converted = []

        if filter_hashes.present?
          filter_hashes = filter_hashes.select do |filter_hash|
            filter_hash["column_name"].present? && filter_hash["condition_values"].present?
          end
          filter_hashes = filter_hashes.group_by { |filter_hash| filter_hash["column_name"] }
          filter_hashes.each do |column_name, sub_filter_hashes|
            condition_values = []
            sub_filter_hashes.each do |filter_hash|
              condition_values += SS::Extensions::Words.mongoize(filter_hash["condition_values"])
            end
            next if condition_values.blank?

            condition_values.select!(&:present?)
            condition_values.uniq!
            next if condition_values.blank?

            form.columns.where(name: column_name).to_a.each do |column|
              filters_converted << {
                "column_id" => column.id,
                "condition_kind" => "any_of",
                "condition_values" => condition_values
              }
            end
          end
        end

        return { "form_id" => form.id } if filters_converted.blank?

        { "form_id" => form.id, "filters" => filters_converted }
      end
    end

    def to_edit_form
      form_ids = []
      values.each do |value|
        form_ids << value.form_id
      end
      form_ids.select!(&:present?)
      form_ids.uniq!
      forms = Cms::Form.in(id: form_ids).to_a

      filters = []
      values.map { |value| value.filters.each { |filter| filters << filter } }
      filters.flatten!

      x_filters = []
      filters.group_by { |filter| filter.column.name }.each do |column_name, grouped_filters|
        condition_values = grouped_filters.map(&:condition_values)
        condition_values.flatten!
        condition_values.compact!
        condition_values.uniq!

        x_filters << OpenStruct.new({ column_name: column_name, condition_values: condition_values })
      end

      OpenStruct.new(forms: forms, filters: x_filters)
    end
  end
end
