class Garbage::Node::BaseImporter
  include Cms::CsvImportBase

  self.required_headers = [ ::Garbage::Node::Page.t(:filename) ]

  attr_reader :site, :node, :user

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(file, opts = {})
    @task = opts[:task]
    put_log("import start #{file.filename}")
    import_csv(file)
  end

  private

  def model
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      Rails.logger.info(message)
    end
  end

  def import_csv(file)
    self.class.each_csv(file) do |row, i|
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
    filename = "#{node.filename}/#{row[model.t(:filename)].to_s.strip}"
    item = model.find_or_initialize_by filename: filename, site_id: site.id
    raise I18n.t('errors.messages.auth_error') unless item.allowed?(:import, user, site: site, node: node)
    item.cur_site = site
    set_page_attributes(row, item)
    raise I18n.t('errors.messages.auth_error') unless item.allowed?(:import, user, site: site, node: node)

    if item.save
      item
    else
      raise item.errors.full_messages.join(", ")
    end
  end

  def set_page_attributes(row, item)
    item.name = row[model.t("name")].to_s.strip
    item.index_name = row[model.t("index_name")].to_s.strip
    item.layout = Cms::Layout.site(site).where(name: row[model.t("layout")].to_s.strip).first
    item.order = row[model.t("order")].to_s.strip
    set_page_groups(row, item)
    item
  end

  def set_page_groups(row, item)
    @groups ||= SS::Group.all.map{ |g| [g.name, g.id] }.to_h
    groups = row[model.t("groups")].to_s.strip.split("\n")
    item.group_ids = groups.map { |g| @groups[g] }.compact
  end
end
