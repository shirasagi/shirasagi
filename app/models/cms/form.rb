class Cms::Form
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Addon::LayoutHtml
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  DEFAULT_TEMPLATE = "{% for value in values %}{{ value }}{% endfor %}".freeze

  set_permission_name 'cms_forms'

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :state, type: String
  field :sub_type, type: String
  has_many :columns, class_name: 'Cms::Column::Base', dependent: :destroy, inverse_of: :form
  has_many :init_columns, class_name: 'Cms::InitColumn', dependent: :destroy, inverse_of: :form

  attr_accessor :cur_user

  permit_params :name, :order, :state, :sub_type

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }
  validates :sub_type, presence: true, inclusion: { in: %w(static entry), allow_blank: true }
  validates :html, liquid_format: true

  scope :and_public, -> {
    where(state: 'public')
  }

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end

  def column_names
    @column_names ||= columns.order_by(order: 1).map { |col| col.name }.compact
  end

  def columns_hash
    @columns_hash ||= columns.order_by(order: 1).map { |col| [col['name'], col] }.to_h
  end

  def state_options
    %w(public closed).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def sub_type_options
    %w(static entry).map do |v|
      [ I18n.t("cms.options.form_sub_type.#{v}"), v ]
    end
  end

  def sub_type_static?
    !sub_type_entry?
  end

  def sub_type_entry?
    sub_type == "entry"
  end

  def build_default_html
    DEFAULT_TEMPLATE
  end

  def render_html(page, registers)
    layout = html.presence || build_default_html
    template = ::Cms.parse_liquid(layout, registers)
    assigns = { "values" => page.column_values.to_liquid, "page" => page.to_liquid }
    template.render(assigns).html_safe
  end
end
