require "csv"

class Event::Page::ImportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(ss_file_id)
    file = ::SS::File.find(ss_file_id) rescue nil

    put_log("import start " + ::File.basename(file.name))
    import_csv(file)

    file.destroy
  end

  def model
    Event::Page
  end

  def import_csv(file)
    table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      begin
        item = update_row(row)
        put_log("update #{i + 1}: #{item.name}")
      rescue => e
        put_log("error  #{i + 1}: #{e}")
      end
    end
  end

  def update_row(row)
    filename = "#{node.filename}/#{row[model.t(:filename)]}"
    item = model.find_or_initialize_by(site_id: site.id, filename: filename)
    item.site = site
    set_page_attributes(row, item)

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
    item.name = value(row, :name)
    item.index_name = value(row, :index_name)
    item.layout = layout
    item.order = value(row, :order)

    # meta
    item.keywords = value(row, :keywords)
    item.description = value(row, :description)
    item.summary_html = value(row, :summary_html)

    # body
    item.html = value(row, :html)

    # event body
    item.schedule = value(row, :schedule)
    item.venue = value(row, :venue)
    item.content = value(row, :content)
    item.cost = value(row, :cost)
    item.related_url = value(row, :related_url)
    item.contact = value(row, :contact)

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
    item.state = state ? state : "public"
  end
end
