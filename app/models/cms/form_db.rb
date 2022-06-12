class Cms::FormDb
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Site
  include Cms::Addon::FormDb::Import
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  attr_accessor :cur_user, :in_file

  set_permission_name 'cms_forms'

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  belongs_to :form, class_name: 'Cms::Form'
  belongs_to :node, class_name: 'Article::Node::Page'

  permit_params :name, :form_id, :node_id

  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :form_id, presence: true

  scope :import_url_setted, -> { where(:form_id.exists => true, :node_id.exists => true, :import_url.exists => true) }

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

  def form_options
    Cms::Form.where(site_id: @cur_site.id, sub_type: 'static').map { |item| [item.name, item.id] }
  end

  def node_options
    Article::Node::Page.where(site_id: @cur_site.id).map { |item| [item.name, item.id] }
  end

  def pages
    pages = Article::Page.site(site).where(form_id: form_id)
    node ? pages.node(node) : pages
  end

  def collect_values(item, name)
    column = form.columns_hash[name]
    col_val = item.column_values.to_a.find { |col| col['name'] == name }
    value = col_val.try(:export_csv_cell).to_s
    width = value.length + value.chars.count { |c| !c.ascii_only? }

    {
      type: I18n.t("mongoid.models.#{column._type.underscore}", default: column._type),
      cell: value.gsub(/\R+/, ' ').slice(0, 20),
      tips: (width > 14) ? value.slice(0, 100) : '',
      full: value,
      form: column.db_form_type,
    }
  end

  def set_page_attributes(item, params)
    if item.new_record?
      item.state = node.state
      item.layout_id = node.page_layout_id || node.layout_id
      item.form_id = form_id
    end

    form.columns.order_by(order: 1).each do |col|
      next unless params.key?(col.name)

      col_val = item.column_values.to_a.find { |cv| cv.name == col.name }
      col_val ||= col.value_type.new(column: col)

      col_val.attributes = { cur_user: @cur_user, cur_site: @cur_site }
      col_val.import_csv_cell(params[col.name])

      item.column_values << col_val if col_val.new_record?
    end
  end

  def save_page(item, params)
    set_page_attributes(item, params)
    item.save
  end

  def save_log(data)
    item = Cms::FormDb::ImportLog.new(site_id: site_id, db_id: id, form_id: form_id, node_id: node_id)
    item.data = data
    item.save
  end

  def export_csv(form, items, options = {})
    column_names = form.column_names
    headers = [Article::Page.t(:name), *column_names]

    require "csv"
    csv = CSV.generate do |data|
      data << headers
      items.each do |item|
        row = [item.name]
        column_names.each do |col_name|
          col_val = item.column_values.to_a.find { |cv| cv.name == col_name }
          row << col_val.try(:export_csv_cell)
        end
        data << row
      end
    end
    encoding = options['encoding'] || 'Shift_JIS'
    csv.encode(encoding, invalid: :replace, undef: :replace)
  end

  def import_task
    task_name = "cms:form_db:import_url"
    Cms::FormDb::ImportTask.find_or_create_by name: task_name, site_id: site_id, db_id: id
  end

  def import_job
    job = Cms::FormDb::ImportUrlJob.bind(site_id: site_id, node_id: node_id, db_id: id)
  end

  def perform_import(options = {})
    import_job.perform_now({ db_id: id, import_url: import_url }.merge(options))
  end

  def perform_import_later(options = {})
    import_job.perform_later({ db_id: id, import_url: import_url }.merge(options))
  end

  # for debug
  def column_values_hash(item)
    exclude = %w(_id _type name order created updated column_id alignment)
    item.column_values.map do |col_val|
      [col_val.name, col_val.attributes.filter { |k, v| !exclude.include?(k.to_s) }]
    end.to_h
  end
end
