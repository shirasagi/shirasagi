class Cms::Column::TextField < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  field :input_type, type: String
  permit_params :input_type

  validates :input_type, presence: true, inclusion: { in: %w(text email tel), allow_blank: true }

  def input_type_options
    %w(text email tel).map do |v|
      [ I18n.t("cms.options.column_input_type.#{v}"), v ]
    end
  end

  def form_options
    options = super
    options['type'] = input_type
    options
  end

  def syntax_check_enabled?
    true
  end
end
