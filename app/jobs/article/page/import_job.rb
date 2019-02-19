require "csv"

class Article::Page::ImportJob < Cms::ApplicationJob
  class << self
    def valid_csv?(file)
      no = 0
      each_csv(file) do |row|
        no += 1
        # check csv record up to 100
        break if no >= 100
      end
      file.rewind

      true
    rescue => e
      false
    end

    def each_csv(file, &block)
      io = file.to_io
      if utf8_file?(io)
        io.seek(3)
        io.set_encoding('UTF-8')
      else
        io.set_encoding('SJIS:UTF-8')
      end

      csv = CSV.new(io, { headers: true })
      csv.each(&block)
    ensure
      io.set_encoding("ASCII-8BIT")
    end

    private

    def utf8_file?(file)
      file.rewind
      bom = file.read(3)
      file.rewind

      bom.force_encoding("UTF-8")
      SS::Csv::UTF8_BOM == bom
    end
  end

  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(ss_file_id)
    file = ::SS::File.find(ss_file_id) rescue nil

    put_log("import start " + ::File.basename(file.name))
    import_csv(file)

    file.destroy
  end

  private

  def model
    Article::Page
  end

  def import_csv(file)
    i = 0
    self.class.each_csv(file) do |row|
      begin
        i += 1
        item = update_row(row)
        put_log("update #{i + 1}: #{item.name}") if item.present?
      rescue => e
        put_log("error  #{i + 1}: #{e}")
      end
    end
  end

  def update_row(row)
    filename = "#{node.filename}/#{row[model.t(:filename)]}"
    item = model.find_or_initialize_by(site_id: site.id, filename: filename)
    raise I18n.t('errors.messages.auth_error') unless item.allowed?(:import, user, site: site, node: node)
    item.site = site
    set_page_attributes(row, item)
    raise I18n.t('errors.messages.auth_error') unless item.allowed?(:import, user, site: site, node: node)

    if item.save
      item
    else
      raise item.errors.full_messages.join(", ")
    end
  end

  def value(row, key)
    key = model.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end

  def to_array(value, delim: "\n")
    value.to_s.split(delim).map(&:strip)
  end

  def ary_value(row, key, delim: "\n")
    to_array(row[model.t(key)], delim: delim)
  end

  def from_label(value, options)
    options.to_h[value].to_s.presence
  end

  def label_value(item, row, key)
    from_label(value(row, key), item.send("#{key}_options"))
  end

  def category_name_tree_to_ids(name_trees)
    category_ids = []
    name_trees.each do |cate|
      ct_list = []
      names = cate.split("/")
      names.each_with_index do |n, d|
        ct = Cms::Node.site(site).where(name: n, depth: d + 1).first
        ct_list << ct if ct
      end

      if ct_list.present? && ct_list.size == names.size
        ct = ct_list.last
        category_ids << ct.id if ct.route =~ /^category\//
      end
    end
    category_ids
  end

  def set_page_attributes(row, item)
    # basic
    layout = Cms::Layout.site(site).where(name: value(row, :layout)).first
    body_layout_id = Cms::BodyLayout.site(site).where(name: value(row, :body_layout_id)).pluck(:_id).first
    item.name = value(row, :name)
    item.index_name = value(row, :index_name)
    item.layout = layout
    item.body_layout_id = body_layout_id
    item.order = value(row, :order)

    form_id = value(row, :form_id)
    if form_id.present?
      form = node.st_forms.where(name: form_id).first
    end
    if form.present? && form.sub_type_entry?
      raise I18n.t("errors.messages.import_with_entry_form_is_not_supported")
    end
    item.form = form

    # meta
    item.keywords = value(row, :keywords)
    item.description = value(row, :description)
    item.summary_html = value(row, :summary_html)

    # body
    item.html = value(row, :html)
    item.body_parts = ary_value(row, :body_part, delim: "\t")

    # category
    category_name_tree = ary_value(row, :categories)
    category_ids = category_name_tree_to_ids(category_name_tree)
    categories = Category::Node::Base.site(site).in(id: category_ids)
    #if node.st_categories.present?
    #  filenames = node.st_categories.pluck(:filename)
    #  filenames += node.st_categories.map { |c| /^#{c.filename}\// }
    #  categories = categories.in(filename: filenames)
    #end
    item.category_ids = categories.pluck(:id)

    # event
    item.event_name = value(row, :event_name)
    item.event_dates = value(row, :event_dates)
    item.event_deadline = value(row, :event_deadline)

    # related pages
    page_names = ary_value(row, :related_pages)
    item.related_page_ids = Cms::Page.site(site).in(filename: page_names).pluck(:id)
    item.related_page_sort = from_label(value(row, "#{model.t(:related_pages)}#{model.t(:related_page_sort)}"), item.related_page_sort_options)

    # crumb
    item.parent_crumb_urls = value(row, :parent_crumb)

    # contact
    group_name = value(row, :contact_group)
    item.contact_state = label_value(item, row, :contact_state)
    item.contact_group_id = SS::Group.where(name: group_name).first.try(:id)
    item.contact_charge = value(row, :contact_charge)
    item.contact_tel = value(row, :contact_tel)
    item.contact_fax = value(row, :contact_fax)
    item.contact_email = value(row, :contact_email)
    item.contact_link_url = value(row, :contact_link_url)
    item.contact_link_name = value(row, :contact_link_name)

    # released
    item.released = value(row, :released)
    item.release_date = value(row, :release_date)
    item.close_date = value(row, :close_date)

    # groups
    group_names = ary_value(row, :groups)
    item.group_ids = SS::Group.in(name: group_names).pluck(:id)
    item.permission_level = value(row, :permission_level)

    # state
    state = label_value(item, row, :state)
    item.state = state.presence || "public"

    # column values
    return if form.blank?

    keys = row.headers.select { |k| k.start_with?("#{form.name}/") }.map { |k| k.split("/") }
    keys = keys.group_by { |form_name, column_name, value_name| column_name }
    values = keys.map do |column_name, value_names|
      column = form.columns.where(name: column_name).first
      next if column.blank?

      values = value_names.map do |_, _, value_name|
        [ value_name, value(row, "#{form.name}/#{column.name}/#{value_name}") ]
      end

      value_type = column.class.value_type
      deserialize_method = "deserialize_column_#{value_type.name.demodulize.underscore}"
      attrs = send(deserialize_method, form, column, values)

      column_value = item.column_values.where(column_id: column.id).first
      if column_value.blank?
        column_value = column.value_type.new(column: column, name: column.name, order: column.order)
      end
      column_value.attributes = Hash[attrs.compact]
      column_value
    end

    item.column_values = values
  end

  def deserialize_column_check_box(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:values)
        [ :values, to_array(value, delim: ",") ]
      end
    end
  end

  def deserialize_column_date_field(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:date)
        [ :date, value ]
      end
    end
  end

  def deserialize_column_file_upload(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      else
        case column.file_type
        when 'image'
          case name
          when I18n.t("cms.column_file_upload.image.file_label")
            [ :file_label, value ]
          when value_type.t(:image_html_type)
            [ :image_html_type, from_label(value, I18n.t("cms.options.column_image_html_type").invert) ]
          end
        when 'video'
          case name
          when I18n.t("cms.column_file_upload.video.text")
            [ :text, value ]
          end
        when 'attachment'
          case name
          when I18n.t("cms.column_file_upload.attachment.file_label")
            [ :file_label, value ]
          end
        when 'banner'
          case name
          when I18n.t("cms.column_file_upload.banner.link_url")
            [ :link_url, value ]
          when I18n.t("cms.column_file_upload.banner.file_label")
            [ :file_label, value ]
          end
        end
      end
    end
  end

  def deserialize_column_free(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:value)
        [ :value, value ]
      end
    end
  end

  def deserialize_column_headline(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:head)
        [ :head, from_label(value, column.headline_list) ]
      when value_type.t(:text)
        [ :text, value ]
      end
    end
  end

  def deserialize_column_list(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:lists)
        [ :lists, to_array(value) ]
      end
    end
  end

  alias deserialize_column_radio_button deserialize_column_free
  alias deserialize_column_select deserialize_column_free
  alias deserialize_column_table deserialize_column_free
  alias deserialize_column_text_area deserialize_column_free
  alias deserialize_column_text_field deserialize_column_free
  alias deserialize_column_url_field deserialize_column_free

  def deserialize_column_url_field2(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:link_url)
        [ :link_url, value ]
      when value_type.t(:link_label)
        [ :link_label, value ]
      end
    end
  end

  def deserialize_column_youtube(form, column, values)
    value_type = column.value_type

    values.map do |name, value|
      case name
      when value_type.t(:alignment)
        [ :alignment, from_label(value, I18n.t("cms.options.alignment").invert) ]
      when value_type.t(:youtube_id)
        [ :youtube_id, value ]
      when value_type.t(:width)
        [ :width, value ]
      when value_type.t(:height)
        [ :height, value ]
      when value_type.t(:auto_width)
        [ :auto_width, from_label(value, I18n.t("cms.column_youtube_auto_width").invert) ]
      end
    end
  end
end
