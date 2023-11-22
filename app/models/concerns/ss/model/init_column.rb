module SS::Model::InitColumn
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    attr_accessor :cur_form

    belongs_to :form, polymorphic: true, inverse_of: :init_columns
    field :order, type: Integer
    belongs_to :column, class_name: 'Cms::Column::Base', polymorphic: true, inverse_of: :init_columns

    permit_params :order, :column_id

    before_validation :set_form_id, if: ->{ @cur_form }

    validates :form_id, presence: true
    validates :column_id, presence: true
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

    scope :form, ->(form) { where(form_id: form.id, form_type: form.class.name) }
  end

  def name
    column.try(:name)
  end

  private

  def set_form_id
    return unless @cur_form
    self.form = @cur_form
  end
end
