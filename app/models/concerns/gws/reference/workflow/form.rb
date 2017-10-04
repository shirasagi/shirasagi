module Gws::Reference::Workflow::Form
  extend ActiveSupport::Concern
  extend SS::Translation

  attr_accessor :cur_form

  included do
    belongs_to :form, class_name: 'Gws::Workflow::Form'

    before_validation :set_form_id, if: ->{ @cur_form }

    scope :form, ->(form) { where(form_id: form.id) }
  end

  private

  def set_form_id
    return unless @cur_form
    self.form_id = @cur_form.id
  end
end
