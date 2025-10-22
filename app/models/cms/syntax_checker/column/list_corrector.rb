class Cms::SyntaxChecker::Column::ListCorrector
  include ActiveModel::Model
  include Cms::SyntaxChecker::Column::Base
  include Cms::SyntaxChecker::Column::BaseCorrector

  def correct
    return unless parsed_params

    values = column_value[attribute]
    corrected_values = []
    values.each do |value|
      corrector = corrector_class.new
      corrected_value = corrector.correct2(value, params: corrector_params)

      corrected_values.push(corrected_value)
    end

    column_value[attribute] = corrected_values
  end
end
