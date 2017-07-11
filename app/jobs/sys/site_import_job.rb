class Sys::SiteImportJob < SS::ApplicationJob
  include Job::SS::TaskFilter
  include Sys::SiteImport::File
  include Sys::SiteImport::Opendata

  def perform
    @dst_site = Cms::Site.find(@task.target_site_id)

    @import_zip = @task.import_file
    @import_dir = "#{Rails.root}/private/import/site-#{@dst_site.host}"

    @task.log("=== Site Import ===")
    @task.log("Site name: #{@dst_site.name}")
    @task.log("Temporary directory: #{@import_dir}")
    @task.log("Import file: #{@import_zip}")

    extract

    init_src_site
    import_cms_groups
    import_cms_users
    import_dst_site

    if @dst_site.errors.present?
      @task.log("Error: Could not create the site. #{@dst_site.name}")
      @task.log(@dst_site.errors.full_messages.join(' '))
      return
    end

    import_cms_roles
    import_cms_user_roles
    import_ss_files
    import_cms_layouts
    import_cms_nodes
    import_cms_parts
    import_cms_pages
    import_cms_page_searches
    import_documents "cms_notices", Cms::Notice
    import_documents "cms_editor_templates", Cms::EditorTemplate
    import_documents "ezine_columns", Ezine::Column
    import_documents "inquiry_columns", Inquiry::Column
    import_documents "kana_dictionaries", Kana::Dictionary
    import_opendata_dataset_groups
    import_opendata_licenses
    update_cms_nodes
    update_cms_pages
    update_opendata_dataset_resources
    update_opendata_app_appfiles

    FileUtils.rm_rf(@import_dir)
    @task.log("Completed.")
  end

  private

  def extract
    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::Archive.open(@import_zip) do |entries|
      entries.each do |entry|
        if entry.name.start_with?('public/')
          path = "#{@dst_site.path}/" + entry.name.encode("UTF-8").tr('\\', '/').sub(/^public\//, '')
        else
          path = "#{@import_dir}/" + entry.name.encode("UTF-8").tr('\\', '/')
        end

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.read)
        end
      end
    end
  end

  def read_json(name)
    path = "#{@import_dir}/#{name}.json"
    return [] unless File.file?(path)
    file = File.read(path)
    JSON.parse(file)
  end

  def init_src_site
    @src_site = Cms::Site.new
    read_json("cms_site").each { |k, v| @src_site[k] = v }
  end

  def import_dst_site
    @dst_site.group_ids = convert_ids(@cms_groups_map, @src_site.group_ids)
    @src_site.attributes.each do |key, val|
      next if key =~ /^(created|updated|name|host|domains|.*_id)$/
      @dst_site[key] = val
    end
    @dst_site.save
  end

  def convert_data(data)
    data['site_id'] = @dst_site.id if data.key?('site_id')
    data['user_id'] = @cms_users_map[data['user_id']] if data['user_id'].present?
    data['group_ids'] = convert_ids(@cms_groups_map, data['group_ids']) if data['group_ids'].present?
    data['node_id'] = @cms_nodes_map[data['node_id']] if data['node_id'].present?
    data['layout_id'] = @cms_layouts_map[data['layout_id']] if data['layout_id'].present?
    data['contact_group_id'] = @cms_groups_map[data['contact_group_id']] if data['contact_group_id'].present?
    data['file_ids'] = convert_ids(@ss_files_map, data['file_ids']) if data['file_ids'].present?
    data['thumb_id'] = @ss_files_map[data['thumb_id']] if data['thumb_id'].present?
    data['image_id'] = @ss_files_map[data['image_id']] if data['image_id'].present?
    data['file_id'] = @ss_files_map[data['file_id']] if data['file_id'].present?
    data['tsv_id'] = @ss_files_map[data['tsv_id']] if data['tsv_id'].present?
    data['icon_id'] = @ss_files_map[data['icon_id']] if data['icon_id'].present?
    data
  end

  def convert_ids(new_ids, old_ids)
    return [] if old_ids.blank?
    old_ids.map { |id| new_ids[id] }.compact
  end

  def import_documents(name, model, fields = nil, &block)
    map = {}
    read_json(name).each do |data|
      id   = data.delete('_id')
      data = convert_data(data)

      if fields
        cond = data.select { |k, v| fields.include?(k) }
        item = model.unscoped.find_or_initialize_by(cond)
      else
        item = model.new
      end

      data.each { |k, v| item[k] = v }
      yield(item) if block_given?

      if save_document(item)
        map[id] = item.id
      end
    end
    map
  end

  def save_document(item)
    def item.set_updated; end
    return true if item.save

    @task.log "#{item.class} - " + item.errors.full_messages.join(' ')
    @task.log "> #{item.to_json}"
    false
  end

  def import_cms_groups
    @cms_groups_map = {}

    read_json("cms_groups").each do |data|
      @cms_groups_map[data['_id']] = Cms::Group.unscoped.where(name: data['name']).first.try(:id)
    end
  end

  def import_cms_users
    @cms_users_map = {}
    @cms_user_roles_map = {}

    read_json("cms_users").each do |data|
      keyword = data['uid'].presence || data['email']
      @cms_users_map[data['_id']] = Cms::User.unscoped.flex_find(keyword).try(:id)
      @cms_user_roles_map[data['_id']] = data['cms_role_ids']
    end
  end

  def import_cms_roles
    @cms_roles_map = import_documents "cms_roles", Cms::Role, %w(site_id name permissions)
  end

  def import_cms_user_roles
    @cms_user_roles_map.each do |user_id, role_ids|
      new_user_id  = @cms_users_map[user_id]
      new_role_ids = convert_ids(@cms_roles_map, role_ids)
      user = Cms::User.unscoped.where(id: new_user_id).first
      user.add_to_set(cms_role_ids: new_role_ids) if user
    end
  end

  def import_cms_layouts
    @cms_layouts_map = import_documents "cms_layouts", Cms::Layout, %w(site_id filename)
  end

  def import_cms_nodes
    @cms_nodes_map = import_documents "cms_nodes", Cms::Node, %w(site_id filename)
  end

  def import_cms_parts
    @cms_parts_map = import_documents "cms_parts", Cms::Part, %w(site_id filename)
  end

  def import_cms_pages
    @cms_pages_map = import_documents "cms_pages", Cms::Page, %w(site_id filename) do |item|
      def item.generate_file; end

      item[:lock_owner_id] = nil
      item[:lock_until] = nil
      item[:category_ids] = convert_ids(@cms_nodes_map, item[:category_ids])
      item[:st_category_ids] = convert_ids(@cms_nodes_map, item[:st_category_ids])
      item[:ads_category_ids] = convert_ids(@cms_nodes_map, item[:ads_category_ids])
      item[:dataset_ids] = convert_ids(@cms_nodes_map, item[:dataset_ids]) # opendata
      item[:area_ids] = convert_ids(@cms_nodes_map, item[:area_ids]) # opendata
    end
  end

  def import_cms_page_searches
    import_documents "cms_page_searches", Cms::PageSearch do |item|
      item[:search_category_ids] = convert_ids(@cms_nodes_map, item[:search_category_ids])
      item[:search_node_ids] = convert_ids(@cms_nodes_map, item[:search_node_ids])
      item[:search_group_ids] = convert_ids(@cms_groups_map, item[:search_group_ids])
      item[:search_user_ids] = convert_ids(@cms_users_map, item[:search_user_ids])
    end
  end

  def update_cms_nodes
    @cms_nodes_map.each do |old_id, id|
      item = Cms::Page.unscoped.find(id) rescue nil
      next unless item

      item[:condition_group_ids] = convert_ids(@cms_groups_map, item[:condition_group_ids])
      item[:st_category_ids] = convert_ids(@cms_nodes_map, item[:st_category_ids])
      item[:my_anpi_post] = @cms_nodes_map[item[:my_anpi_post]] if item[:my_anpi_post].present?
      item[:anpi_mail] = @cms_nodes_map[item[:anpi_mail]] if item[:anpi_mail].present?
      save_document(item)
    end
  end

  def update_cms_pages
    @cms_pages_map.each do |old_id, id|
      item = Cms::Page.unscoped.find(id) rescue nil
      next unless item
      def item.generate_file; end

      item[:related_page_ids] = convert_ids(@cms_pages_map, item[:related_page_ids])
      save_document(item)
    end
  end
end
