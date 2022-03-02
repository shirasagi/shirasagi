class Cms::FormDb
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Site
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  attr_accessor :cur_user, :in_file

  set_permission_name 'cms_forms'

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :import_url, type: String

  belongs_to :form, class_name: 'Cms::Form'
  belongs_to :node, class_name: 'Article::Node::Page'

  permit_params :name, :form_id, :node_id, :import_url

  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :form_id, presence: true
  validates :import_url, format: /\Ahttps?:\/\//, if: -> { import_url.present? }

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
  end

  def form_options
    Cms::Form.where(site_id: @cur_site.id, sub_type: 'static').map { |item| [item.name, item.id] }
  end

  def node_options
    Article::Node::Page.where(site_id: @cur_site.id).map { |item| [item.name, item.id] }
  end

  def pages
    pages = Article::Page.site(site).where(form_id: id)
    node ? pages.node(node) : pages
  end

  def collect_values(item, name)
    column = form.columns_hash[name]
    col_val = item.column_values.to_a.find { |col| col['name'] == name }
    value = col_val.try(:export_csv_cell).to_s
    width = value.length + value.chars.reject(&:ascii_only?).length

    {
      type: I18n.t("mongoid.models.#{column._type.underscore}", default: column._type),
      cell: value.gsub(/\R+/, ' ').slice(0, 20),
      tips: (width > 14) ? value.slice(0, 100) : '',
      full: value,
      form: column.db_form_type,
    }
  end

  def save_page(item, params)
    if item.new_record?
      item.state = node.state
      item.layout_id = node.page_layout_id || node.layout_id
      item.form_id = id
    end

    form.columns.order_by(order: 1).each do |col|
      col_val = item.column_values.to_a.find { |cv| cv.name == col.name }
      col_val ||= item.column_values.build(
        _type: col.value_type.name, column: col, name: col.name, order: col.order
      )
      col_val.attributes = { cur_user: @cur_user, cur_site: @cur_site }
      col_val.import_csv_cell(params[col.name])
    end

    item.save
  end

  def import_csv
    errors.add(:base, :invalid_csv) if in_file.blank?
    return false if errors.present?

    require "csv"
    ::CSV.foreach(in_file.path, headers: true, encoding: 'SJIS:UTF-8') do |csv_row|
      params = csv_row.to_hash
      page_name = params.shift[1].presence
      next unless page_name

      item = Article::Page.find_by(name: page_name) rescue nil
      item ||= Article::Page.new(name: page_name, cur_site: site, cur_user: @cur_user, cur_node: node)

      unless save_page(item, params)
        dump item.errors.full_messages
        errors.add :base, item.errors.full_messages.join('/')
      end
    end

    errors.blank?
  end

  # for debug
  def column_values_hash(item)
    exclude = %w(_id _type name order created updated column_id alignment)
    item.column_values.map do |col_val|
      [col_val.name, col_val.attributes.filter { |k, v| !exclude.include?(k.to_s) }]
    end.to_h
  end
end
