module Sys::SiteImport::Contents
  extend ActiveSupport::Concern

  def import_cms_layouts
    @cms_layouts_map = import_documents "cms_layouts", Cms::Layout, %w(site_id filename)
  end

  def import_cms_body_layouts
    @cms_body_layouts_map = import_documents "cms_body_layouts", Cms::BodyLayout
  end

  def import_cms_nodes
    @cms_nodes_map = import_documents "cms_nodes", Cms::Node, %w(site_id filename) do |item|
      item[:opendata_site_ids] = [] if item[:opendata_site_ids].present?
    end
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
      item[:area_ids] = convert_ids(@cms_nodes_map, item[:area_ids])
      item[:column_values] = nil # TODO: cms/form, cms/column ?
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

  def import_cms_notices
    import_documents "cms_notices", Cms::Notice
  end

  def import_cms_editor_templates
    import_documents "cms_editor_templates", Cms::EditorTemplate
  end

  def import_cms_theme_templates
    import_documents "cms_theme_templates", Cms::ThemeTemplate, %w(site_id class_name)
  end

  def import_cms_source_cleaner_templates
    import_documents "cms_source_cleaner_templates", Cms::SourceCleanerTemplate
  end

  def import_ezine_columns
    import_documents "ezine_columns", Ezine::Column
  end

  def import_inquiry_columns
    import_documents "inquiry_columns", Inquiry::Column
  end

  def import_kana_dictionaries
    import_documents "kana_dictionaries", Kana::Dictionary
  end

  def update_cms_nodes
    @cms_nodes_map.each do |old_id, id|
      item = Cms::Node.unscoped.find(id) rescue nil
      next unless item

      item[:condition_group_ids] = convert_ids(@cms_groups_map, item[:condition_group_ids])
      item[:st_category_ids] = convert_ids(@cms_nodes_map, item[:st_category_ids])
      item[:st_location_ids] = convert_ids(@cms_nodes_map, item[:st_location_ids])
      item[:st_service_ids] = convert_ids(@cms_nodes_map, item[:st_service_ids])
      item[:category_ids] = convert_ids(@cms_nodes_map, item[:category_ids])
      item[:location_ids] = convert_ids(@cms_nodes_map, item[:location_ids])
      item[:service_ids] = convert_ids(@cms_nodes_map, item[:service_ids])
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

      item[:master_id] = @cms_pages_map[item[:master_id]]
      item[:related_page_ids] = convert_ids(@cms_pages_map, item[:related_page_ids])
      item[:dataset_group_ids] = convert_ids(@opendata_dataset_groups_map, item[:dataset_group_ids])
      item[:dataset_ids] = convert_ids(@cms_pages_map, item[:dataset_ids])
      item[:app_ids] = convert_ids(@cms_pages_map, item[:app_ids])
      item[:opendata_area_ids] = convert_ids(@cms_nodes_map, item[:opendata_area_ids])
      item[:opendata_category_ids] = convert_ids(@cms_nodes_map, item[:opendata_category_ids])
      item[:opendata_dataset_ids] = convert_ids(@cms_pages_map, item[:opendata_dataset_ids])
      item[:opendata_dataset_group_ids] = convert_ids(@opendata_dataset_groups_map, item[:opendata_dataset_group_ids])
      item[:opendata_license_ids] = convert_ids(@opendata_licenses_map, item[:opendata_license_ids])
      save_document(item)
    end
  end
end
