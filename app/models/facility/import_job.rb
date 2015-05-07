require "csv"

class Facility::ImportJob
  include Job::Worker

  public
    def put_log(message)
      Rails.logger.info(message)
    end

    def call(ss_file_id, host, filename)
      @ss_file  = ::Facility::TempFile.where(id: ss_file_id).first
      @cur_site = SS::Site.where(host: host).first
      @cur_node = ::Facility::Node::Node.where(filename: filename, site_id: @cur_site.id).first

      put_log("import start " + ::File.basename(@ss_file.name))
      import_csv(@ss_file)

      @ss_file.destroy
    end

    def import_csv(file)
      @model = ::Facility::Node::Page
      @destroy_pages = @model.where(filename: /^#{@cur_node.filename}\//).map(&:filename)

      table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        begin
          name = update_row(row)
          put_log("update #{i + 1}: #{name}")
        rescue => e
          put_log("error  #{i + 1}: #{e}")
        end
      end

      dump @destroy_pages
      @model.in(filename: @destroy_pages).each do |item|
        put_log("destroy : #{item.name}")
        item.destroy
      end
    end

    # TODO Enable rubocop
    # rubocop:disable Metrics/AbcSize
    def update_row(row)
      filename = "#{@cur_node.filename}/#{row[@model.t(:filename)]}"
      item = @model.find_or_create_by filename: filename
      item.cur_site = @cur_site

      item.name            = row[@model.t(:name)]
      item.layout          = Cms::Layout.where(name: row[@model.t(:layout)]).first
      item.kana            = row[@model.t(:kana)]
      item.address         = row[@model.t(:address)]
      item.postcode        = row[@model.t(:postcode)]
      item.tel             = row[@model.t(:tel)]
      item.fax             = row[@model.t(:fax)]
      item.related_url     = row[@model.t(:related_url)]
      item.additional_info = row.to_h.select {|k, v| k =~ /^#{@model.t(:additional_info)}[:：]/ && v.present? }.
        map { |k, v| {:field => k, :value => v} }

      ids = @cur_node.st_categories.in(name: row[@model.t(:categories)].to_s.split(/\n/)).map(&:id)
      item.category_ids = SS::Extensions::ObjectIds.new(ids)

      ids = @cur_node.st_locations.in(name: row[@model.t(:locations)].to_s.split(/\n/)).map(&:id)
      item.location_ids = SS::Extensions::ObjectIds.new(ids)

      ids = @cur_node.st_services.in(name: row[@model.t(:services)].to_s.split(/\n/)).map(&:id)
      item.service_ids  = SS::Extensions::ObjectIds.new(ids)

      ids = SS::Group.in(name: row[@model.t(:groups)].to_s.split(/\n/)).map(&:id)
      item.group_ids    = SS::Extensions::ObjectIds.new(ids)

      if item.save
        name = item.name
      else
        raise item.errors.full_messages.join(", ")
      end

      if row[@model.t(:map_points)].present?
        filename = "#{filename}/map.html"
        map = ::Facility::Map.find_or_create_by filename: filename
        points = row[@model.t(:map_points)].split(/\n/).map do |loc|
          { loc: Map::Extensions::Loc.mongoize(loc) }
        end

        map.name = "map"
        map.cur_site = @cur_site
        map.map_points = Map::Extensions::Points.new(points)
        map.save
        name += " #{map.map_points.first[:loc]}"
      end

      @destroy_pages.delete(filename)
      return name
    end
end
