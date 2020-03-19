require 'nkf'

class Sys::SiteImportJob < SS::ApplicationJob
  include Job::SS::TaskFilter
  include Sys::SiteImport::Contents
  include Sys::SiteImport::Opendata
  include Sys::SiteImport::File

  def perform
    @dst_site = Cms::Site.find(@task.target_site_id)

    @import_zip = @task.import_file
    @import_dir = "#{Rails.root}/private/import/site-#{@dst_site.host}"

    @task.log("=== Site Import ===")
    @task.log("Site name: #{@dst_site.name}")
    @task.log("Temporary directory: #{@import_dir}")
    @task.log("Import file: #{@import_zip}")

    invoke :extract

    init_src_site
    init_mapping
    import_cms_groups
    import_cms_users
    import_dst_site

    if @dst_site.errors.present?
      @task.log("Error: Could not create the site. #{@dst_site.name}")
      @task.log(@dst_site.errors.full_messages.join(' '))
      return
    end

    invoke :import_cms_roles
    invoke :import_cms_users_roles
    invoke :import_ss_files
    invoke :import_cms_forms
    invoke :import_cms_columns
    invoke :import_cms_loop_settings
    invoke :import_cms_layouts
    invoke :import_cms_body_layouts
    invoke :import_cms_nodes
    invoke :import_cms_parts
    invoke :import_cms_pages
    invoke :import_cms_page_searches
    invoke :import_cms_notices
    invoke :import_cms_editor_templates
    invoke :import_cms_theme_templates
    invoke :import_cms_source_cleaner_templates
    invoke :import_ezine_columns
    invoke :import_inquiry_columns
    invoke :import_kana_dictionaries
    invoke :import_opendata_dataset_groups
    invoke :import_opendata_licenses
    invoke :update_cms_nodes
    invoke :update_cms_pages
    invoke :update_ss_files
    invoke :update_opendata_dataset_resources
    invoke :update_opendata_app_appfiles
    invoke :update_ss_files_url

    FileUtils.rm_rf(@import_dir)
    @task.log("Completed.")
  end

  private

  def invoke(method)
    @task.log("- " + method.to_s.sub('_', ' '))
    send(method)
  end

  def extract
    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::File.open(@import_zip) do |entries|
      entries.each do |entry|
        name = entry.name
        if entry.gp_flags & Zip::Entry::EFS
          name.force_encoding("UTF-8")
        else
          name = NKF.nkf('-w', name)
        end

        if name.start_with?('public/')
          path = "#{@dst_site.path}/" + name.tr('\\', '/').sub(/^public\//, '')
        else
          path = "#{@import_dir}/" + name.tr('\\', '/')
        end

        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          File.binwrite(path, entry.get_input_stream.read)
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

  def init_mapping
    @cms_groups_map = {}
    @cms_users_map = {}
    @cms_user_roles_map = {}
    @cms_roles_map = {}
    @ss_files_map = {}
    @ss_files_url = {}
    @cms_forms_map = {}
    @cms_columns_map = {}
    @cms_loop_settings_map = {}
    @cms_layouts_map = {}
    @cms_body_layouts_map = {}
    @cms_nodes_map = {}
    @cms_parts_map = {}
    @cms_pages_map = {}
    @opendata_dataset_groups_map = {}
    @opendata_licenses_map = {}
  end

  def import_dst_site
    @dst_site.group_ids = convert_ids(@cms_groups_map, @src_site.group_ids)
    @src_site.attributes.each do |key, val|
      next if key =~ /^(created|updated|name|host|domains|.*_id|.*_ids)$/
      @dst_site[key] = val
    end
    @dst_site.save
  end

  def convert_data(data)
    data['site_id'] = @dst_site.id if data.key?('site_id')
    data['user_id'] = @cms_users_map[data['user_id']] if data['user_id'].present?
    data['node_id'] = @cms_nodes_map[data['node_id']] if data['node_id'].present?

    data['group_ids'] = convert_ids(@cms_groups_map, data['group_ids']) if data['group_ids'].present?

    %w(layout_id page_layout_id urgency_default_layout_id).each do |name|
      data[name] = @cms_layouts_map[data[name]] if data[name].present?
    end

    data['body_layout_id'] = @cms_body_layouts_map[data['body_layout_id']] if data['body_layout_id'].present?
    data['contact_group_id'] = @cms_groups_map[data['contact_group_id']] if data['contact_group_id'].present?
    data['file_ids'] = convert_ids(@ss_files_map, data['file_ids']) if data['file_ids'].present?

    %w(thumb_id image_id file_id tsv_id icon_id).each do |name|
      data[name] = @ss_files_map[data[name]] if data[name].present?
    end

    data['form_id'] = @cms_forms_map[data['form_id']] if data['form_id'].present?
    data['st_form_ids'] = convert_ids(@cms_forms_map, data['st_form_ids']) if data['st_form_ids'].present?

    data['loop_setting_id'] = @cms_loop_settings_map[data['loop_setting_id']] if data['loop_setting_id'].present?

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

      if data.key?("_type")
        effective_model = data["_type"].constantize rescue model
      else
        effective_model = model
      end

      if fields
        cond = data.select { |k, v| fields.include?(k) }
        item = effective_model.unscoped.find_or_initialize_by(cond)
      else
        item = effective_model.new
      end

      data.each { |k, v| item[k] = v }
      item = item.becomes_with_route || item rescue item
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
    @task.log("- import cms_groups")
    @cms_groups_map = import_documents "cms_groups", Cms::Group, %w(name)
  end

  def import_cms_users
    @cms_users_map = {}
    @cms_user_roles_map = {}

    read_json("cms_users").each do |data|
      keyword = data['uid'].presence || data['email']
      id = data.delete('_id')

      cms_role_ids = data.delete("cms_role_ids")
      data.delete("sys_role_ids")

      data = convert_data(data)
      item = Cms::User.unscoped.flex_find(keyword)
      if item.nil?
        item = Cms::User.new
        data.each { |k, v| item[k] = v }
        next if !save_document(item)
      end

      @cms_users_map[id] = item.id
      @cms_user_roles_map[id] = cms_role_ids
    end
  end

  def import_cms_roles
    @task.log("- import cms_roles")
    @cms_roles_map = import_documents "cms_roles", Cms::Role, %w(site_id name permissions)
  end

  def import_cms_users_roles
    @cms_user_roles_map.each do |user_id, role_ids|
      new_user_id  = @cms_users_map[user_id]
      new_role_ids = convert_ids(@cms_roles_map, role_ids)
      user = Cms::User.unscoped.where(id: new_user_id).first
      user.add_to_set(cms_role_ids: new_role_ids) if user
    end
  end
end
