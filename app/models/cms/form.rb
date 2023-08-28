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

  scope :and_public, ->(_date = nil) { where(state: 'public') }

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

    EXCLUDES_FORM_FIELDS_FROM_EXPORT = %w(_id site_id group_ids created updated).freeze
    EXCLUDES_COLUMN_FIELDS_FROM_EXPORT = %w(_id site_id form_id created updated).freeze

    def export_json(items)
      items.map do |form|
        form_data = form.attributes.reject { |c| EXCLUDES_FORM_FIELDS_FROM_EXPORT.include?(c) }
        form_data[:groups] = form.groups.map(&:name)

        form_data[:columns] = form.columns.map do |col|
          col.attributes.reject { |c| EXCLUDES_COLUMN_FIELDS_FROM_EXPORT.include?(c) }
        end
        form_data[:init_columns] = form.init_columns.map do |col|
          col.attributes.reject { |c| EXCLUDES_COLUMN_FIELDS_FROM_EXPORT.include?(c) }
        end

        form_data
      end
    end
  end

  def column_names
    @column_names ||= columns.order_by(order: 1).map { |col| col.name }.compact
  end

  def columns_hash
    @columns_hash ||= columns.order_by(order: 1).index_by { |col| col['_id'] }
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

  def import_json(options = {})
    json_file = options[:file].presence || in_file
    json_data = json_file.read
    json_data = JSON.parse(json_data) rescue nil
    errors.add(:base, :malformed_json) unless json_data.instance_of?(Array)
    return false if errors.any?

    json_data.each_with_index do |form_data, idx|
      form_data = form_data.with_indifferent_access
      form_data.delete(:_id)
      unless import_json_row(form_data)
        errors.add(:base, "[#{idx + 1}] #{form_data[:name]} - #{I18n.t('ss.notice.not_saved_successfully')}")
      end
    end

    errors.empty?
  end

  def import_json_row(form_data)
    fields = Cms::Form.fields.keys

    form = Cms::Form.site(@cur_site).where(name: form_data[:name]).first
    form ||= Cms::Form.new(form_data.filter { |c| fields.include?(c) })
    return unless form.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    form.cur_site = @cur_site
    form.cur_user = @cur_user
    form.group_ids |= Cms::Group.where(:name.in => form_data[:groups]).pluck(:id) # uniq
    return unless form.save

    result = true

    form_data[:columns].to_a.each do |col_data|
      col_class = col_data[:_type].constantize
      col = col_class.site(@cur_site).form(form).where(name: col_data[:name]).first || col_class.new

      col_data.delete(:_id)
      col.attributes = col_data
      col.cur_site = @cur_site
      col.form_id = form.id
      if col.changed?
        result = false unless col.save
      end
    end

    result
  rescue => e
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end
end
