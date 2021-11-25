class Faq::Page::Importer
  include Cms::CsvImportBase

  self.required_headers = [ Faq::Page.t(:filename) ]

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
    Faq::Page
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      Rails.logger.info(message)
    end
  end

  def import_csv(file)
    SS::Csv.foreach_row(file, headers: true) do |row, i|
      item = update_row(row)
      put_log("update #{i + 1}: #{item.name}")
    rescue => e
      put_log("error  #{i + 1}: #{e}")
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
    row[model.t(key)].try(:strip)
  end

  def ary_value(row, key)
    row[model.t(key)].to_s.split(/\n/).map(&:strip)
  end

  def label_value(item, row, key)
    item.send("#{key}_options").to_h[value(row, key)]
  end

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
    # basic
    layout = Cms::Layout.site(site).where(name: value(row, :layout)).first
    item.name = value(row, :name)
    item.index_name = value(row, :index_name)
    item.layout = layout
    item.order = value(row, :order)

    # meta
    item.keywords = value(row, :keywords)
    item.description = value(row, :description)
    item.summary_html = value(row, :summary_html)

    # body
    item.question = value(row, :question)
    item.html = value(row, :html)

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

    # related pages
    page_names = ary_value(row, :related_pages)
    item.related_page_ids = Cms::Page.site(site).in(filename: page_names).pluck(:id)

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
    released_type = label_value(item, row, :released_type)
    item.released_type = released_type
    item.released = value(row, :released)
    item.release_date = value(row, :release_date)
    item.close_date = value(row, :close_date)

    # groups
    group_names = ary_value(row, :groups)
    item.group_ids = SS::Group.in(name: group_names).pluck(:id)
    unless SS.config.ss.disable_permission_level
      item.permission_level = value(row, :permission_level)
    end

    # state
    state = label_value(item, row, :state)
    item.state = state || "public"
  end
end
