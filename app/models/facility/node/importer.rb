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
    @count_errors = []

    put_log("import start #{file.filename}")
    import_csv(file)
    put_log(I18n.t("cms.count_log_of_errors", number_of_errors: @count_errors.length))
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

    @count_errors << message.scan("error")
    @count_errors.delete([])
  end

  def import_csv(file)
    table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      row_num = i + 2
      begin
        update_row(row, row_num)
      rescue => e
        put_log("error #{row_num}#{I18n.t("cms.row_num")}: #{e}")
      end
    end
  end

  def update_row(row, row_num)
    filename = "#{node.filename}/#{row[model.t(:filename)]}"
    item = model.find_or_initialize_by filename: filename, site_id: site.id
    item.cur_site = site
    set_page_attributes(row, item)
    put_log_of_insert(item, row_num, row)

    if item.save
      name = item.name
    else
      raise item.errors.full_messages.join(", ")
    end

    if row[model.t(:map_points)].present?
      filename = "#{filename}/map.html"
      map = ::Facility::Map.find_or_create_by filename: filename
      set_map_attributes(row, map, row_num)
      map.site = site
      map.save
      name += " #{map.map_points.first.try(:[], "loc")}"
    end

    return name
  end

  def put_log_of_insert(item, row_num, row)
    put_log_of_category(item.name, row_num, row)
    put_log_of_location(item.name, row_num, row)
    put_log_of_service(item.name, row_num, row)
    put_log_of_group(item.name, row_num, row)

    return put_log(I18n.t("cms.log_of_the_failed_import", row_num: row_num)) if item.invalid?
    return put_log("add #{row_num}#{I18n.t("cms.row_num")}:  #{item.name}") if item.new_record?

    item.changes.each do |change_data|
      changed_field = change_data[0]
      before_changing_data = change_data[1][0]
      after_changing_data = change_data[1][1]
      next if changed_field == "additional_info" && before_changing_data.nil? && after_changing_data == []

      field_name = "update #{row_num}#{I18n.t("cms.row_num")}:  #{I18n.t("mongoid.attributes.facility/node/page.#{changed_field}")}："

      case changed_field
      when "category_ids"
        before_changing_category = before_changing_data.map {|id| Facility::Node::Category.find(id).name }
        after_changing_category = after_changing_data.map {|id| Facility::Node::Category.find(id).name }
        put_log("#{field_name}#{before_changing_category} → #{after_changing_category}")
      when "location_ids"
        before_changing_location = before_changing_data.map {|id| Facility::Node::Location.find(id).name }
        after_changing_location = after_changing_data.map {|id| Facility::Node::Location.find(id).name }
        put_log("#{field_name}#{before_changing_location} → #{after_changing_location}")
      when "group_ids"
        before_changing_group = before_changing_data.map {|id| SS::Group.find(id).name }
        after_changing_group = after_changing_data.map {|id| SS::Group.find(id).name }
        put_log("#{field_name}#{before_changing_group} → #{after_changing_group}")
      when "service_ids"
        before_changing_servise = before_changing_data.map {|id| Facility::Node::Service.find(id).name }
        after_changing_servise = after_changing_data.map {|id| Facility::Node::Service.find(id).name }
        put_log("#{field_name}#{before_changing_servise} → #{after_changing_servise}")
      else
        put_log("#{field_name}#{before_changing_data} → #{after_changing_data}")
      end
    end
  end

  def put_log_of_category(item_name, row_num, row)
    names = row[model.t(:categories)].to_s.split(/\n/).map(&:strip)
    facility_category = node.st_category_ids.map do |category_id|
      Facility::Node::Category.find(category_id)
    end

    category_in_db = facility_category.map(&:name)

    names.each do |category_in_csv|
      next if category_in_db.include?(category_in_csv)
      put_log(I18n.t("cms.log_of_the_failed_category", category: category_in_csv, category: category_in_csv, row_num: row_num))
    end
  end

  def put_log_of_location(item_name, row_num, row)
    names = row[model.t(:locations)].to_s.split(/\n/).map(&:strip)
    facility_location = node.st_location_ids.map do |location_id|
      Facility::Node::Location.find(location_id)
    end

    location_in_db = facility_location.map(&:name)

    names.each do |location_in_csv|
      next if location_in_db.include?(location_in_csv)
      put_log(I18n.t("cms.log_of_the_failed_location", location: location_in_csv, row_num: row_num))
    end
  end

  def put_log_of_service(item_name, row_num, row)
    names = row[model.t(:services)].to_s.split(/\n/).map(&:strip)
    facility_service = node.st_service_ids.map do |service_id|
      Facility::Node::Service.find(service_id)
    end

    service_in_db = facility_service.map(&:name)

    names.each do |service_in_csv|
      next if service_in_db.include?(service_in_csv)
      put_log(I18n.t("cms.log_of_the_failed_service", service: service_in_csv, row_num: row_num))
    end
  end

  def put_log_of_group(item_name, row_num, row)
    names = row[model.t(:groups)].to_s.split(/\n/).map(&:strip)
    facility_group = node.group_ids.map do |group_id|
      SS::Group.find(group_id)
    end

    group_in_db = facility_group.map(&:name)

    names.each do |group_in_csv|
      next if group_in_db.include?(group_in_csv)
      put_log(I18n.t("cms.log_of_the_failed_group", group: group_in_csv, row_num: row_num))
    end
  end

  def set_page_attributes(row, item)
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

    set_page_categories(row, item)
    ids = SS::Group.in(name: row[model.t(:groups)].to_s.split(/\n/)).map(&:id)
    item.group_ids = SS::Extensions::ObjectIds.new(ids)
  end

  def set_page_categories(row, item)
    names = row[model.t(:categories)].to_s.split(/\n/).map(&:strip)
    ids = node.st_categories.in(name: names).map(&:id)

    item.category_ids = SS::Extensions::ObjectIds.new(ids)

    names = row[model.t(:locations)].to_s.split(/\n/).map(&:strip)
    ids = node.st_locations.in(name: names).map(&:id)
    item.location_ids = SS::Extensions::ObjectIds.new(ids)

    names = row[model.t(:services)].to_s.split(/\n/).map(&:strip)
    ids = node.st_services.in(name: names).map(&:id)
    item.service_ids = SS::Extensions::ObjectIds.new(ids)
  end

  def set_map_attributes(row, item, row_num)
    points = row[model.t(:map_points)].split(/\n/).map do |loc|
      { loc: Map::Extensions::Loc.mongoize(loc) }
    end

    item.name = "map"
    item.map_points = Map::Extensions::Points.new(points)

    return if item.new_record?

    item.changes.each do |change_data|
      before_changing_data = change_data[1][0]#[0][:loc]
      after_changing_data = change_data[1][1]#[0][:loc]
      put_log("update #{row_num}#{I18n.t("cms.row_num")}:  #{I18n.t("mongoid.attributes.facility/node/page.#{change_data[0]}")}：#{before_changing_data} → #{after_changing_data}")
    end
  end
end
