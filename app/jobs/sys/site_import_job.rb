require 'nkf'

class Sys::SiteImportJob < SS::ApplicationJob
  #include Job::SS::TaskFilter
  include Sys::SiteImport::Contents
  include Sys::SiteImport::Opendata
  include Sys::SiteImport::File

  def mock_task
    task = OpenStruct.new
    def task.log(message)
      Rails.logger.info(message)
      puts message
    end
    task
  end

  def perform(import_file)
    @dst_site = site
    @task = mock_task

    @import_zip = import_file
    @import_dir = "#{Rails.root}/private/import/site-#{@dst_site.host}"

    @task.log("=== Site Import ===")
    @task.log("Site name: #{@dst_site.name}")
    @task.log("Temporary directory: #{@import_dir}")
    @task.log("Import file: #{@import_zip}")

    invoke :extract

    init_src_site
    init_mapping
    invoke :import_cms_groups
    invoke :import_cms_users
    invoke :import_dst_site
    invoke :import_cms_editor_templates

    if @dst_site.errors.present?
      @task.log("Error: Could not create the site. #{@dst_site.name}")
      @task.log(@dst_site.errors.full_messages.join(' '))
      return
    end

    invoke :import_cms_roles
    invoke :import_cms_users_roles
    invoke :import_ss_files
    invoke :import_cms_forms
    invoke :import_cms_loop_settings
    invoke :import_cms_layouts
    invoke :import_cms_body_layouts
    invoke :import_cms_nodes
    invoke :import_cms_columns
    invoke :import_cms_parts
    invoke :import_cms_pages
    # invoke :import_cms_page_searches
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
    invoke :update_cms_parts
    invoke :update_ss_files
    invoke :update_opendata_dataset_resources
    invoke :update_opendata_app_appfiles
    invoke :update_ss_files_url
    invoke :import_source_cleaner_templates
    invoke :import_theme_templates
    invoke :import_cms_word_dictionaries
    invoke :import_cms_translate_langs
    invoke :import_cms_translate_text_caches
    invoke :import_cms_page_search
    invoke :import_cms_guides
    invoke :import_cms_check_links_ignore_urls

    FileUtils.rm_rf(@import_dir)
    @task.log("Completed.")
  rescue => e
    puts "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
    raise
  end

  private

  def invoke(method)
    @task.log("- " + method.to_s.sub('_', ' '))
    time = Benchmark.realtime { send(method) }
    @task.log("- completed #{method} (#{time * 1000} ms)")
  end

  def extract
    FileUtils.rm_rf(@import_dir)
    FileUtils.mkdir_p(@import_dir)

    Zip::File.open(@import_zip) do |entries|
      entries.each do |entry|
        next if entry.directory?

        name = SS::Zip.safe_zip_entry_name(entry)
        if name.start_with?('public/')
          root_dir = @dst_site.path
          name = name.sub(/^public\//, '')
        else
          root_dir = @import_dir
        end

        path = ::File.expand_path(name, root_dir)
        next unless path.start_with?("#{root_dir}/")

        dirname = ::File.dirname(path)
        unless ::Dir.exist?(dirname)
          ::FileUtils.mkdir_p(dirname)
        end
        ::File.binwrite(path, entry.get_input_stream.read)
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
    @cms_contact_groups_map = {}
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
      next if key =~ /^(created|updated|name|host|domains|subdir|translate_.*|.*_id|.*_ids)$/
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

    if data['contact_group_contact_id'].present?
      old_id = data['contact_group_contact_id']
      if old_id.is_a?(Hash) && old_id.key?("$oid")
        old_id = old_id["$oid"]
      end
      data['contact_group_contact_id'] = @cms_contact_groups_map[old_id]
    end

    data['file_ids'] = convert_ids(@ss_files_map, data['file_ids']) if data['file_ids'].present?

    %w(thumb_id image_id file_id tsv_id icon_id).each do |name|
      data[name] = @ss_files_map[data[name]] if data[name].present?
    end

    data['form_id'] = @cms_forms_map[data['form_id']] if data['form_id'].present?
    data['st_form_ids'] = convert_ids(@cms_forms_map, data['st_form_ids']) if data['st_form_ids'].present?
    data['st_form_default_id'] = @cms_forms_map[data['st_form_default_id']] if data['st_form_default_id'].present?

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

      if id.is_a?(Hash) && id.key?("$oid")
        id = id["$oid"]
      end

      if data.key?("_type")
        effective_model = data["_type"].constantize rescue model
      elsif data.key?("route") && model.instance_methods.include?(:becomes_with_route)
        effective_model = model.new.becomes_with_route(data["route"]).class rescue model
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
      yield(item, data) if block

      if save_document(item)
        map[id] = item.id
      end
    end
    map
  end

  def save_document(item)
    def item.set_updated; end
    def item.save_backup; end
    def item.generate_file; end
    return true if item.save

    @task.log "#{item.class} - " + item.errors.full_messages.join(' ')
    @task.log "> #{item.to_json}"
    false
  end

  def import_cms_groups
    name = "cms_groups"
    model = Cms::Group
    fields = %w(name)

    # import_documents
    read_json(name).each do |data|
      id   = data.delete('_id')
      data = convert_data(data)

      cond = data.select { |k, v| fields.include?(k) }
      item = model.find_or_initialize_by(cond)

      data.each do |k, v|
        next if k == "contact_groups"
        item[k] = v
      end

      next if !save_document(item)
      @cms_groups_map[id] = item.id

      # after save (embedded save)
      next if data['contact_groups'].blank?
      data['contact_groups'].each do |dist|
        dist.deep_stringify_keys!
        old_id = dist["_id"]
        if old_id.is_a?(Hash) && old_id.key?("$oid")
          old_id = old_id["$oid"]
        end
        contact_groups = item.contact_groups.to_a

        # 属性が全て一致する連絡先
        contact = contact_groups.find { |c| c.same_contact?(dist) }
        # 識別名が同じ連絡先
        contact ||= contact_groups.find { |item| item.name == dist["name"] }

        if contact.nil?
          # 連絡先がない為、作成を試みる
          contact_email = dist["contact_email"].to_s.squish
          main_contact = contact_groups.find { |c| c.main_state == "main" }

          if contact_email.end_with?("@example.jp")
            # ただし、メールアドレスが reset されているものについては、主の連絡先に置き換える
            contact = main_contact if main_contact
          else
            main_state = main_contact ? nil : dist["main_state"]
            contact = item.contact_groups.create(
              name: dist["name"],
              contact_group_name: dist["contact_group_name"],
              contact_charge: dist["contact_charge"],
              contact_tel: dist["contact_tel"],
              contact_fax: dist["contact_fax"],
              contact_email: dist["contact_email"],
              contact_postal_code: dist["contact_postal_code"],
              contact_address: dist["contact_address"],
              contact_link_url: dist["contact_link_url"],
              contact_link_name: dist["contact_link_name"],
              main_state: main_state)
          end
        end
        if contact && contact.errors.blank?
          @cms_contact_groups_map[old_id] = contact.id.to_s
        end
      end
      data.delete("contact_groups")
    end
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

  def import_cms_editor_templates
    read_json("cms_editor_templates").each do |data|
      id   = data.delete('_id')
      data = convert_data(data)

      thumb_id = data['thumb_id']
      file_ids = data['file_ids']

      # Find or initialize the editor template for the destination site
      cond = { name: data['name'], site_id: @dst_site.id }
      item = Cms::EditorTemplate.find_or_initialize_by(cond)

      data.each { |k, v| item[k] = v }

      if thumb_id.present?
        new_thumb_id = @ss_files_map[thumb_id]
        if new_thumb_id.present?
          thumb_file = SS::File.find(new_thumb_id)
          thumb_file.update(owner_item: item, site_id: @dst_site.id)
          item.thumb_id = thumb_file.id
        end
      end

      # Process additional files
      if file_ids.present?
        new_file_ids = convert_ids(@ss_files_map, file_ids)
        item.file_ids = new_file_ids
      end

      save_document(item)
    end
  end

  def import_source_cleaner_templates
    read_json("cms_source_cleaner_templates").each do |data|
      id   = data.delete('_id')
      data = convert_data(data)
      cond = { name: data['name'], site_id: @dst_site.id }
      item = Cms::SourceCleanerTemplate.find_or_initialize_by(cond)

      data.each { |k, v| item[k] = v }

      save_document(item)
    end
  end

  def import_theme_templates
    read_json("cms_theme_templates").each do |data|
      id   = data.delete('_id')
      data = convert_data(data)
      cond = { name: data['name'], site_id: @dst_site.id }
      item = Cms::ThemeTemplate.find_or_initialize_by(cond)
      data.each { |k, v| item[k] = v }

      save_document(item)
    end
  end

  def import_cms_word_dictionaries
    dictionaries = Cms::WordDictionary.site(@src_site)
    dictionaries.each do |d|
      data = d.attributes
      id   = data.delete('_id')
      data = convert_data(data)
      cond = { name: data['name'], site_id: @dst_site.id }
      item = Cms::WordDictionary.find_or_initialize_by(cond)
      data.each { |k, v| item[k] = v }

      save_document(item)
    end
  end

  def import_cms_translate_langs
    translate_langs = ::Translate::Lang.site(@src_site)
    translate_langs.each do |d|
      data = d.attributes
      id   = data.delete('_id')
      data = convert_data(data)
      cond = { name: data['name'], site_id: @dst_site.id }
      item = ::Translate::Lang.find_or_initialize_by(cond)
      data.each { |k, v| item[k] = v }

      save_document(item)
    end
  end

  def import_cms_translate_text_caches
    translate_text_caches = ::Translate::TextCache.site(@src_site)
    translate_text_caches.each do |d|
      data = d.attributes
      id   = data.delete('_id')
      data = convert_data(data)
      cond = { site_id: @dst_site.id }
      item = ::Translate::TextCache.find_or_initialize_by(cond)
      data.each { |k, v| item[k] = v }

      save_document(item)
    end
  end

  def import_cms_page_search
    page_searches = Cms::PageSearch.site(@src_site)
    page_searches.each do |d|
      data = d.attributes
      id   = data.delete('_id')
      data = convert_data(data)
      data['search_layout_ids'] = convert_ids(@cms_layouts_map, data['search_layout_ids'])
      data['search_category_ids'] = convert_ids(@cms_nodes_map, data['search_category_ids'])
      data['search_node_ids'] = convert_ids(@cms_nodes_map, data['search_node_ids'])
      if data['search_group_ids'].present?
        data['search_group_ids'] = data['search_group_ids'].map { |group_id| @cms_groups_map.fetch(group_id, group_id) }
      end
      if data['search_user_ids'].present?
        data['search_user_ids'] = data['search_user_ids'].map { |user_id| @cms_users_map.fetch(user_id, user_id) }
      end
      cond = { name: data['name'], site_id: @dst_site.id }
      item = Cms::PageSearch.find_or_initialize_by(cond)
      data.each { |k, v| item[k] = v }

      save_document(item)
    end
  end

  def import_cms_guides
    @guide_diagram_point_map = {}

    embeded_edges = {}
    read_json("guide_diagram_point").each do |data|
      klass = data["_type"].constantize
      id    = data.delete('_id')
      edges = data.delete('edges')

      data = convert_data(data)
      cond = { site_id: @dst_site.id, node_id: data["node_id"], id_name: data["id_name"] }
      item = klass.find_or_initialize_by(cond)
      data.each { |k, v| item[k] = v }

      if save_document(item)
        embeded_edges[item.id] = edges if edges.present?
        @guide_diagram_point_map[id] = item.id
      end
    end

    embeded_edges.each do |id, values|
      point = Guide::Diagram::Point.find(id)
      point.edges = values.map do |data|
        data.delete('_id')
        data["point_ids"] = convert_ids(@guide_diagram_point_map, data["point_ids"])
        data["not_applicable_point_ids"] = convert_ids(@guide_diagram_point_map, data["not_applicable_point_ids"])
        data["optional_necessary_point_ids"] = convert_ids(@guide_diagram_point_map, data["optional_necessary_point_ids"])

        item = Guide::Diagram::Edge.new
        data.each { |k, v| item[k] = v }
        item
      end
      save_document(point)
    end
  end

  def import_cms_check_links_ignore_urls
    import_documents "cms_check_links_ignore_urls", Cms::CheckLinks::IgnoreUrl, %w(site_id name)
  end
end
