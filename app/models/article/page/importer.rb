class Article::Page::Importer
  include Cms::CsvImportBase

  self.required_headers = [ Article::Page.t(:filename) ]

  attr_reader :site, :node, :user

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(file, opts = {})
    @task = opts[:task]
    put_log("import start " + ::File.basename(file.name))
    import_csv(file)
  end

  private

  def model
    Article::Page
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      Rails.logger.info(message)
    end
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
    filename = "#{node.filename}/#{value(row, :filename)}"
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

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def category_name_tree_to_ids(name_trees)
    category_ids = []
    name_trees.each do |cate|
      names = cate.split("/")

      last_index = names.size - 1
      last_name = names[last_index]

      parent_names = names.slice(0...(names.size - 1))

      cond = { name: last_name, depth: last_index + 1, route: /^category\// }
      node_ids = Cms::Node.site(site).where(cond).pluck(:id)
      node_ids.each do |node_id|
        cate = Cms::Node.find(node_id)

        if parent_names == cate.parents.pluck(:name)
          category_ids << cate.id
        end
      end
    end
    category_ids
  end

  def set_page_attributes(row, item)
    create_importer
    @importer.import_row(row, item)
  end

  def create_importer
    @importer ||= SS::Csv.draw(:import, context: self, model: model) do |importer|
      define_importer_basic(importer)
      define_importer_meta(importer)
      define_importer_body(importer)
      define_importer_category(importer)
      define_importer_event(importer)
      define_importer_related_pages(importer)
      define_importer_crumb(importer)
      define_importer_contact(importer)
      define_importer_released(importer)
      define_importer_groups(importer)
      define_importer_state(importer)
      define_importer_forms(importer)
    end.create
  end

  def define_importer_basic(importer)
    importer.simple_column :name
    importer.simple_column :index_name
    importer.simple_column :layout do |row, item, head, value|
      item.layout = value.present? ? Cms::Layout.site(site).where(name: value).first : nil
    end
    importer.simple_column :body_layout_id do |row, item, head, value|
      item.body_layout = value.present? ? Cms::BodyLayout.site(site).where(name: value).first : nil
    end
    importer.simple_column :order
    importer.simple_column :redirect_link
    importer.simple_column :form_id do |row, item, head, value|
      item.form = value.present? ? node.st_forms.where(name: value).first : nil
    end
  end

  def define_importer_meta(importer)
    importer.simple_column :keywords
    importer.simple_column :description
    importer.simple_column :summary_html
  end

  def define_importer_body(importer)
    importer.simple_column :html
    importer.simple_column :body_parts do |row, item, head, value|
      item.body_parts = to_array(value, delim: "\t")
    end
  end

  def define_importer_category(importer)
    importer.simple_column :categories do |row, item, head, value|
      category_ids = category_name_tree_to_ids(to_array(value))
      categories = Category::Node::Base.site(site).in(id: category_ids)
      #if node.st_categories.present?
      #  filenames = node.st_categories.pluck(:filename)
      #  filenames += node.st_categories.map { |c| /^#{c.filename}\// }
      #  categories = categories.in(filename: filenames)
      #end
      item.category_ids = categories.pluck(:id)
    end
  end

  def define_importer_event(importer)
    importer.simple_column :event_name
    importer.simple_column :event_dates
    importer.simple_column :event_deadline
  end

  def define_importer_related_pages(importer)
    importer.simple_column :related_pages do |row, item, head, value|
      page_names = to_array(value)
      item.related_page_ids = Cms::Page.site(site).in(filename: page_names).pluck(:id)
    end
    column_name = "#{model.t(:related_pages)}#{model.t(:related_page_sort)}"
    importer.simple_column :related_page_sort, name: column_name do |row, item, head, value|
      item.related_page_sort = from_label(value, item.related_page_sort_options)
    end
  end

  def define_importer_crumb(importer)
    importer.simple_column :parent_crumb_urls, name: model.t(:parent_crumb)
  end

  def define_importer_contact(importer)
    importer.simple_column :contact_state do |row, item, head, value|
      item.contact_state = from_label(value, item.contact_state_options)
    end
    importer.simple_column :contact_group do |row, item, head, value|
      item.contact_group = SS::Group.where(name: value).first
    end
    importer.simple_column :contact_charge
    importer.simple_column :contact_tel
    importer.simple_column :contact_fax
    importer.simple_column :contact_email
    importer.simple_column :contact_link_url
    importer.simple_column :contact_link_name
  end

  def define_importer_released(importer)
    importer.simple_column :released
    importer.simple_column :release_date
    importer.simple_column :close_date
  end

  def define_importer_groups(importer)
    importer.simple_column :groups do |row, item, head, value|
      group_names = to_array(value)
      item.group_ids = SS::Group.in(name: group_names).pluck(:id)
    end
    importer.simple_column :permission_level
  end

  def define_importer_state(importer)
    importer.simple_column :state do |row, item, head, value|
      state = from_label(value, item.state_options, item.state_private_options)
      item.state = state.presence || "public"
    end
  end

  def define_importer_forms(importer)
    return if !node.respond_to?(:st_forms)

    node.st_forms.each do |form|
      # currently entry type form is not supported
      next if !form.sub_type_static?

      importer.form form.name do
        form.columns.each do |column|
          importer.column column.name do |row, item, _form, _column, values|
            import_column(row, item, form, column, values)
          end
        end
      end
    end
  end

  def import_column(_row, item, _form, column, values)
    column_value = item.column_values.where(column_id: column.id).first
    if column_value.blank?
      column_value = item.column_values.build(
        _type: column.value_type.name, column: column, name: column.name, order: column.order
      )
    end
    column_value.import_csv(values)
    column_value
  end
end
