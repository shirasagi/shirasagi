module SS::Copy::CmsPages
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_cms_page(src_page)
    Rails.logger.info("♦︎ SS::Copy::CmsPages[copy_cms_page] コピー開始: " \
                      "#{src_page.filename}(#{src_page.id}), route: #{src_page.route}")
    copy_cms_content(:pages, src_page, copy_cms_page_options)
    Rails.logger.info("♦︎ SS::Copy::CmsPages[copy_cms_page] コピー完了: #{src_page.filename} → #{dest_page.try(:filename)}:" \
                      "(dest_page.id:#{dest_page.id}), route: #{dest_page.route}")
  rescue => e
    @task.log("#{src_page.filename}(#{src_page.id}): ページのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def resolve_page_reference(id)
    id
  end

  private

  def copy_cms_page_options
    {
      before: method(:before_copy_cms_page),
      after: method(:after_copy_cms_page)
    }
  end

  def before_copy_cms_page(src_page)
    Rails.logger.debug("#{src_page.filename}(#{src_page.id}): ページのコピーを開始します。")
  end

  def after_copy_cms_page(src_page, dest_page)
    Rails.logger.info("♦︎ SS::Copy::CmsPages[after_copy_cms_page] コピー開始: #{src_page.filename}(#{src_page.id}), " \
                      "route: #{src_page.route}, related_page_ids=#{src_page.try(:related_page_ids)}")

    case src_page.route
    when "opendata/dataset"
      copy_opendata_dataset_groups(src_page, dest_page)
      copy_opendata_dataset_resources(src_page, dest_page)
    when "opendata/app"
      copy_opendata_app_appfiles(src_page, dest_page)
    end

    Rails.logger.debug("♦︎ DEBUG: dest_page.related_page_ids=#{dest_page.related_page_ids.inspect} " \
                       "(class=#{dest_page.related_page_ids.class})")
    if dest_page.respond_to?(:column_values)
      dest_page.column_values = src_page.column_values.map do |src_column_value|
        dest_column_value = src_column_value.dup
        dest_column_value.column_id = resolve_reference(:column, src_column_value.column_id)
        if dest_column_value.respond_to?(:file_id) && dest_column_value.file_id.present?
          dest_column_value.file_id = resolve_reference(:file, src_column_value.file_id)
        end
        if dest_column_value.respond_to?(:file_ids)
          dest_column_value.file_ids = resolve_reference(:file, src_column_value.file_ids)
        end
        update_html_links(src_column_value, dest_column_value, names: %w(value))
        dest_column_value
      end
    end
    Rails.logger.info("♦︎ SS::Copy::CmsPages[after_copy_cms_page] コピー完了: #{src_page.filename} → #{dest_page.try(:filename)}:" \
                      "(dest_page.id:#{dest_page.id}), route: #{dest_page.route}," \
                      "related_page_ids=#{dest_page.try(:related_page_ids)}")
    @task.log("#{src_page.filename}(#{src_page.id}): ページをコピーしました。")
  end

  def copy_opendata_dataset_groups(src_page, dest_page)
    dest_page.dataset_group_ids = src_page.dataset_groups.map do |dataset_group|
      resolve_opendata_dataset_group_reference(dataset_group.id)
    end

    dest_page.save!
  end

  def copy_opendata_dataset_resources(src_page, dest_page)
    cache(:opendata_dataset_resources, src_page.id) do
      src_page.resources.each do |resource|
        dest_resource = dest_page.resources.new
        dest_resource.source_url = resource.source_url
        dest_resource.name = resource.name
        dest_resource.text = resource.text
        dest_resource.filename = resource.filename
        dest_resource.format = resource.format
        dest_resource.rdf_iri = resource.rdf_iri
        dest_resource.rdf_error = resource.rdf_error
        dest_resource.license_id = resolve_opendata_license_reference(resource.license_id) if resource.license_id.present?
        dest_resource.file_id = resolve_file_reference(resource.file_id) if resource.file_id.present?
        dest_resource.tsv_id = resolve_file_reference(resource.tsv_id) if resource.tsv_id.present?
        dest_resource.assoc_site_id = resource.assoc_site_id
        dest_resource.assoc_node_id = resource.assoc_node_id
        dest_resource.assoc_page_id = resource.assoc_page_id
        dest_resource.assoc_filename = resource.assoc_filename
        dest_resource.save!(validate: false)
      end
      dest_page.id
    end
  end

  def copy_opendata_app_appfiles(src_page, dest_page)
    cache(:opendata_app_appfiles, src_page.id) do
      src_page.appfiles.each do |appfile|
        dest_appfile = dest_page.appfiles.new
        dest_appfile.text = appfile.text
        dest_appfile.filename = appfile.filename
        dest_appfile.format = appfile.format
        dest_appfile.file_id = resolve_file_reference(appfile.file_id) if appfile.file_id.present?
        dest_appfile.save!
      end
      dest_page.id
    end
  end
end
