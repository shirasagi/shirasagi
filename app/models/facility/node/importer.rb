class Facility::Node::Importer
  include Cms::CsvImportBase

  self.required_headers = [ ::Facility::Node::Page.t(:filename) ]

  attr_reader :site, :node, :user

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(file, opts = {})
    @task = opts[:task]
    @count_errors = 0
    @changed_data = 0

    put_log("import start #{file.filename}")
    import_csv(file)
    put_log(I18n.t("cms.count_log_of_errors", number_of_errors: @count_errors))
  end

  private

  def model
    ::Facility::Node::Page
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
      row_num = i + 2
      begin
        update_row(row, row_num)
      rescue => e
        put_log("#{I18n.t("cms.row_error", row_num: row_num)}: #{e}")
      end
      put_log("")
    end
  end

  def update_row(row, row_num)
    filename = "#{node.filename}/#{row[model.t(:filename)]}"
    item = model.find_or_initialize_by filename: filename, site_id: site.id
    set_page_attributes(row, item)
    set_category_ids(row, item)
    set_location_ids(row, item)
    set_service_ids(row, item)
    set_group_ids(row, item)
    put_attribute_log(item, row_num, row)

    save_facility(item, row_num)

    return if row[model.t(:map_points)].blank?

    save_map(filename, row, row_num)
  end

  def set_page_attributes(row, item)
    item.cur_site        = site
    item.name            = row[model.t(:name)].try(:squish)
    item.layout          = Cms::Layout.site(site).where(name: row[model.t(:layout)].try(:squish)).first
    item.kana            = row[model.t(:kana)].try(:squish)
    item.address         = row[model.t(:address)].try(:squish)
    item.postcode        = row[model.t(:postcode)].try(:squish)
    item.tel             = row[model.t(:tel)].try(:squish)
    item.fax             = row[model.t(:fax)].try(:squish)
    item.related_url     = row[model.t(:related_url)].try(:gsub, /[\r\n]/, " ")
    item.additional_info = row.to_h.select { |k, v| k =~ /^#{model.t(:additional_info)}[:：]/ && v.present? }.
        map { |k, v| {:field => k.sub(/^#{model.t(:additional_info)}[:：]/, ""), :value => v} }
  end

  def set_category_ids(row, item)
    names = row[model.t(:categories)].to_s.split(/\n/).map(&:strip)
    category_ids = node.st_categories.in(name: names).map(&:id)
    item.category_ids = SS::Extensions::ObjectIds.new(category_ids)
  end

  def set_location_ids(row, item)
    names = row[model.t(:locations)].to_s.split(/\n/).map(&:strip)
    location_ids = node.st_locations.in(name: names).map(&:id)
    item.location_ids = SS::Extensions::ObjectIds.new(location_ids)
  end

  def set_service_ids(row, item)
    names = row[model.t(:services)].to_s.split(/\n/).map(&:strip)
    service_ids = node.st_services.in(name: names).map(&:id)
    item.service_ids = SS::Extensions::ObjectIds.new(service_ids)
  end

  def set_group_ids(row, item)
    ids = SS::Group.in(name: row[model.t(:groups)].to_s.split(/\n/)).map(&:id)
    item.group_ids = SS::Extensions::ObjectIds.new(ids)
  end

  def put_attribute_log(item, row_num, row)
    put_category_log(item.name, row_num, row)
    put_location_log(item.name, row_num, row)
    put_service_log(item.name, row_num, row)
    put_group_log(item.name, row_num, row)

    return if item.invalid? || item.new_record?

    put_update_log(item, row_num)
  end

  def put_category_log(item_name, row_num, row)
    inputted_categories = row[model.t(:categories)].to_s.split(/\n/).map(&:strip)
    category_in_db = Facility::Node::Category.in(id: node.st_category_ids).pluck(:name)

    inputted_categories.each do |category|
      next if category_in_db.include?(category)

      @count_errors += 1
      put_log(I18n.t("cms.failed_category_log", category: category, row_num: row_num))
    end
  end

  def put_location_log(item_name, row_num, row)
    inputted_locations = row[model.t(:locations)].to_s.split(/\n/).map(&:strip)
    location_in_db = Facility::Node::Location.in(id: node.st_location_ids).pluck(:name)

    inputted_locations.each do |location|
      next if location_in_db.include?(location)

      @count_errors += 1
      put_log(I18n.t("cms.failed_location_log", location: location, row_num: row_num))
    end
  end

  def put_service_log(item_name, row_num, row)
    inputted_services = row[model.t(:services)].to_s.split(/\n/).map(&:strip)
    service_in_db = Facility::Node::Service.in(id: node.st_service_ids).pluck(:name)

    inputted_services.each do |service|
      next if service_in_db.include?(service)

      @count_errors += 1
      put_log(I18n.t("cms.failed_service_log", service: service, row_num: row_num))
    end
  end

  def put_group_log(item_name, row_num, row)
    inputted_groups = row[model.t(:groups)].to_s.split(/\n/).map(&:strip)
    group_in_db = SS::Group.in(id: node.group_ids).pluck(:name)

    inputted_groups.each do |group|
      next if group_in_db.include?(group)

      @count_errors += 1
      put_log(I18n.t("cms.failed_group_log", group: group, row_num: row_num))
    end
  end

  def put_update_log(item, row_num)
    item.changes.each do |change_data|
      data_before_change, data_after_change = change_data[1]
      next if data_before_change.blank? && data_after_change.blank?

      @changed_data += 1
      changed_field = change_data[0]
      locale_filed = I18n.t("mongoid.attributes.facility/node/page.#{changed_field}")
      updated_field = I18n.t("cms.updated_field", row_num: row_num, field: locale_filed)

      if item.fields[changed_field].options[:metadata].nil?
        put_log("#{updated_field} #{data_before_change} to #{data_after_change}")
      else
        klass = item.fields[changed_field].options[:metadata][:elem_class].constantize
        metadata_before_change = klass.in(id: data_before_change).pluck(:name)
        metadata_after_change = klass.in(id: data_after_change).pluck(:name)
        put_log("#{updated_field} #{metadata_before_change} to #{metadata_after_change}")
      end
    end
  end

  def save_facility(item, row_num)
    name = item.name

    if item.new_record? && item.save
      put_log(I18n.t("cms.new_record", row_num: row_num, name: item.name))
    elsif @changed_data > 0 && item.update
      put_log(I18n.t("cms.update_record", row_num: row_num, name: item.name))
    else
      @count_errors += 1
      err_msgs = item.errors.full_messages.join(",")
      put_log(I18n.t("cms.failed_to_save", row_num: row_num, err_msgs: err_msgs, name: name))
    end
  end

  def save_map(filename, row, row_num)
    filename = "#{filename}/map.html"
    map = ::Facility::Map.find_or_create_by(filename: filename)
    set_map_attributes(row, map, row_num)
    map.site = site
    map.save
  end

  def set_map_attributes(row, item, row_num)
    points = row[model.t(:map_points)].split(/\n/).map do |loc|
      { loc: Map::Extensions::Loc.mongoize(loc) }
    end

    item.name = "map"
    item.map_points = Map::Extensions::Points.new(points)

    return if item.new_record?

    item.changes.each do |changed_data|
      changed_field = changed_data[0]
      data_before_change, data_after_change = changed_data[1]
      locale_filed = I18n.t("mongoid.attributes.facility/node/page.#{changed_field}")
      updated_field = I18n.t("cms.updated_field", row_num: row_num, field: locale_filed)
      put_log("#{updated_field} #{data_before_change} to #{data_after_change}")
    end
  end
end
