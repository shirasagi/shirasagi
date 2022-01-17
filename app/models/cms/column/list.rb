class Cms::Column::List < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  field :list_type, type: String
  permit_params :list_type

  validates :list_type, presence: true, inclusion: { in: %w(ol ul), allow_blank: true }

  def list_type_options
    %w(ol ul).map do |v|
      [ I18n.t("cms.options.column_list_type.#{v}"), v ]
    end
  end

  def syntax_check_enabled?
    true
  end

  def link_check_enabled?
    true
  end

  def db_form_type
    { type: 'textarea', rows: 4 }
  end
end
