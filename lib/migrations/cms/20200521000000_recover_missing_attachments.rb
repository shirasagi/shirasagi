class SS::Migration20200521000000
  include SS::Migration::Base

  depends_on "20200318000000"

  def change
    each_page do |page|
      page = page.becomes_with_route rescue page

      site = find_site(page.site_id)
      next if site.blank? # page is existed in deleted site

      recover_html(site, page)
      recover_free_column(site, page)
    end
  end

  class << self
    def each_file_id(html, &block)
      return if html.blank?

      html.scan(/"\/fs\/(\d\/)+_\//) do
        matched = $&
        matched = matched[5..-4]
        matched = matched.gsub("/", "")
        yield matched.to_i
      end
    end
  end

  private

  def each_page(&block)
    criteria = Cms::Page.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end

  def recover_html(site, page)
    return unless page.respond_to?(:html)
    return if page.html.blank?

    missing_files = []
    self.class.each_file_id(page.html) do |file_id|
      file = find_missing_file(site, file_id)
      next if file.blank?

      file.owner_item = page
      missing_files << file
    end

    return if missing_files.blank?

    page.file_ids = merge_array(page.file_ids, missing_files.map(&:id))
    page.save(validate: false)

    associate_all_files_to(missing_files, page)
  end

  def recover_free_column(site, page)
    return unless page.respond_to?(:column_values)

    missing_files = []
    column_value_file_map = {}
    page.column_values.each do |column_value|
      next unless column_value.is_a?(Cms::Column::Value::Free)
      next if column_value.value.blank?

      self.class.each_file_id(column_value.value) do |file_id|
        file = find_missing_file(site, file_id)
        next if file.blank?

        file.owner_item = page
        missing_files << file

        column_value_id = column_value.id.to_s
        column_value_file_map[column_value_id] ||= []
        column_value_file_map[column_value_id] << file.id
      end
    end

    return if missing_files.blank?

    column_value_file_map.each do |column_value_id, file_ids|
      column_value = page.column_values.where(id: column_value_id).first
      column_value.file_ids = merge_array(column_value.file_ids, file_ids).dup
    end
    page.save(validate: false)
    associate_all_files_to(missing_files, page)
  end

  def find_site(site_id)
    @all_sites ||= Cms::Site.all.unscoped.to_a
    @all_sites.find { |site| site.id == site_id }
  end

  def find_missing_file(site, file_id)
    @all_missing_files ||= begin
      criteria = SS::File.all.unscoped
      criteria = criteria.exists(site_id: true)
      criteria = criteria.exists(owner_item_id: false)
      criteria = criteria.where(model: "ss/temp_file")
      criteria.to_a
    end
    @all_missing_files.find { |file| file.site_id == site.id && file.id == file_id && file.owner_item_id.blank? }
  end

  def associate_all_files_to(files, to_page)
    files.each do |file|
      next if file.owner_item.present?
      next if file.model != "ss/temp_file"

      file.owner_item = to_page
      file.model = to_page.class.model_name.i18n_key.to_s
      file.save
    end
  end

  def merge_array(array, values)
    array = [] if array.nil?

    values.each do |value|
      next if array.include?(value)
      array << value
    end

    array
  end
end
