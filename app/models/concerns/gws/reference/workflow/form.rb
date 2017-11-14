module Gws::Reference::Workflow::Form
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :cur_form

    belongs_to :form, class_name: 'Gws::Workflow::Form'

    before_validation :set_form_id, if: ->{ @cur_form }

    scope :form, ->(form) { where(form_id: form.id) }
  end

  def cur_form
    @cur_form ||= self.form
  end

  private

  def set_form_id
    return unless @cur_form
    self.form_id = @cur_form.id
  end
end
