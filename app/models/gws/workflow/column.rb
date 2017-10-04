class Gws::Workflow::Column
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Workflow::Form
  include Gws::Addon::Facility::InputSetting

  field :name, type: String
  field :order, type: Integer, default: 0
  field :tooltips, type: SS::Extensions::Lines

  permit_params :name, :order, :tooltips

  class << self
    def to_permitted_fields(prefix)
      params = criteria.map do |item|
        if item.input_type == 'check_box'
          { item.id.to_s => [] }
        else
          item.id.to_s
        end
      end

      { prefix => params }
    end

    def to_validator(options)
      criteria = self.criteria.dup
      ActiveModel::BlockValidator.new(options.dup) do |record, attribute, value|
        criteria.each do |item|
          item.validate_value(record, attribute, value)
        end
      end
    end
  end
end
