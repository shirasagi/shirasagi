module Cms::SyntaxChecker::Column::BaseCorrector
  extend ActiveSupport::Concern
  include ActiveModel::Model
  include Cms::SyntaxChecker::Column::Base

  included do
    attr_accessor :cur_site, :cur_user, :page, :column_value, :attribute, :params, :corrector_class, :corrector_params
  end

  def correct
    return unless parsed_params

    value = column_value[attribute]
    value = value.freeze

    corrector = corrector_class.new
    corrected_value = corrector.correct2(value, params: corrector_params)

    column_value[attribute] = corrected_value
    corrected_value
  end
end
