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
      item.skip_remove_files_recursively = true
    end
  end

  def import_cms_parts
    @cms_parts_map = import_documents "cms_parts", Cms::Part, %w(site_id filename)
  end

  def import_cms_pages
    @cms_pages_map = import_documents "cms_pages", Cms::Page, %w(site_id filename) do |item, data|
      def item.generate_file; end
      item.skip_validate_seq_filename = true if item.is_a?(Cms::Page::SequencedFilename)

      item[:lock_owner_id] = nil
      item[:lock_until] = nil
      item[:category_ids] = convert_ids(@cms_nodes_map, item[:category_ids])
      item[:st_category_ids] = convert_ids(@cms_nodes_map, item[:st_category_ids])
      item[:ads_category_ids] = convert_ids(@cms_nodes_map, item[:ads_category_ids])
      item[:area_ids] = convert_ids(@cms_nodes_map, item[:area_ids])
      if item[:column_values].present?
        item.column_values.each do |column_value|
          column_value['column_id'] = @cms_columns_map["$oid" => column_value['column_id'].to_s]
          if column_value['file_id'].present?
            column_value['file_id'] = @ss_files_map[column_value['file_id']]
          end
          if column_value['file_ids'].present?
            column_value['file_ids'] = column_value['file_ids'].map do |file_id|
              @ss_files_map[file_id]
            end
            if column_value.value.present?
              @ss_files_url.each do |src, dst|
                src_path = /#{::Regexp.escape(::File.dirname(src))}\/[^"]*/
                column_value.value = column_value.value.gsub(src_path, dst)
              end
            end
          end
          column_value
        end
      end
      if data["event_recurrences"].present?
        item.event_recurrences = data["event_recurrences"].map do |event_recurrence|
          Event::Extensions::Recurrence.new(event_recurrence["attributes"])
        end
      end
    end
  end

  def import_cms_page_searches
    import_documents "cms_page_searches", Cms::PageSearch do |item|
      item[:search_category_ids] = convert_ids(@cms_nodes_map, item[:search_category_ids])
      item[:search_node_ids] = convert_ids(@cms_nodes_map, item[:search_node_ids])
      item[:search_group_ids] = convert_ids(@cms_groups_map, item[:search_group_ids])
      item[:search_layout_ids] = convert_ids(@cms_layouts_map, item[:search_layout_ids])
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

  def import_cms_forms
    @cms_forms_map = import_documents "cms_forms", Cms::Form
  end

  def import_cms_columns
    @cms_columns_map = import_documents "cms_columns", Cms::Column::Base do |item, data|
      if item.is_a?(Cms::Column::SelectPage)
        item[:node_ids] = convert_ids(@cms_nodes_map, item[:node_ids])
      end
    end
  end

  def import_cms_loop_settings
    @cms_loop_settings_map = import_documents "cms_loop_settings", Cms::LoopSetting
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
      if item.respond_to?(:column_values)
        item.column_values.each do |column_value|
          if column_value.is_a?(Cms::Column::Value::SelectPage)
            column_value.page_id = @cms_pages_map[column_value.page_id]
          end
        end
      end
      save_document(item)
    end
  end
end
