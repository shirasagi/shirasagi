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
    table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      row_num = i + 2
      begin
        update_row(row, row_num)
      rescue => e
        @count_errors.succ
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
    if item.invalid?
      @count_errors.succ
      put_log(I18n.t("cms.log_of_the_failed_import", row_num: row_num))
    elsif item.new_record?
      put_log("add #{row_num}#{I18n.t("cms.row_num")}:  #{item.name}")
    end

    put_log_of_category(item.name, row_num, row)
    put_log_of_location(item.name, row_num, row)
    put_log_of_service(item.name, row_num, row)
    put_log_of_group(item.name, row_num, row)

    return if item.invalid? || item.new_record?

    put_log_of_update(item, row_num)
  end

  def put_log_of_category(item_name, row_num, row)
    inputted_category = row[model.t(:categories)].to_s.split(/\n/).map(&:strip)
    category_in_db = node.st_category_ids.map { |category_id| Facility::Node::Category.find(category_id) }.map(&:name)

    inputted_category.each do |category|
      next if category_in_db.include?(category)
      @count_errors.succ
      put_log(I18n.t("cms.log_of_the_failed_category", category: category, row_num: row_num))
    end
  end

  def put_log_of_location(item_name, row_num, row)
    inputted_location = row[model.t(:locations)].to_s.split(/\n/).map(&:strip)
    location_in_db = node.st_location_ids.map { |location_id| Facility::Node::Location.find(location_id) }.map(&:name)

    inputted_location.each do |location|
      next if inputted_location.include?(location)
      @count_errors.succ
      put_log(I18n.t("cms.log_of_the_failed_location", location: location, row_num: row_num))
    end
  end

  def put_log_of_service(item_name, row_num, row)
    inputted_service = row[model.t(:services)].to_s.split(/\n/).map(&:strip)
    service_in_db = node.st_service_ids.map { |service_id| Facility::Node::Service.find(service_id) }.map(&:name)

    inputted_service.each do |service|
      next if service_in_db.include?(service)
      @count_errors.succ
      put_log(I18n.t("cms.log_of_the_failed_service", service: service, row_num: row_num))
    end
  end

  def put_log_of_group(item_name, row_num, row)
    inputted_group = row[model.t(:groups)].to_s.split(/\n/).map(&:strip)
    group_in_db = node.group_ids.map { |group_id| SS::Group.find(group_id) }.map(&:name)

    inputted_group.each do |group|
      next if group_in_db.include?(group)
      @count_errors.succ
      put_log(I18n.t("cms.log_of_the_failed_group", group: group, row_num: row_num))
    end
  end

  def put_log_of_update(item, row_num)
    item.changes.each do |change_data|
      changed_field = change_data[0]
      before_changing_data = change_data[1][0]
      after_changing_data = change_data[1][1]
      next if changed_field == "additional_info" && before_changing_data.nil? && after_changing_data == []

      field_name = "update #{row_num}#{I18n.t("cms.row_num")}:  #{I18n.t("mongoid.attributes.facility/node/page.#{changed_field}")}："

      if item.fields[change_data[0]].options[:metadata].nil?
        klass = item.fields[change_data[0]].options[:klass]
      else
        klass = item.fields[change_data[0]].options[:metadata][:elem_class].constantize
      end

      return put_log("#{field_name}#{before_changing_data} → #{after_changing_data}") if klass == model

      before_changing_metadata = klass.in(id: before_changing_data).pluck(:name)
      after_changing_metadata = klass.in(id: after_changing_data).pluck(:name)
      put_log("#{field_name}#{before_changing_metadata} → #{after_changing_metadata}")
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
