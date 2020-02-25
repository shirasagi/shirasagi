module Opendata::Resource::Previewable
  extend ActiveSupport::Concern
  include Opendata::TsvParseable
  include Opendata::PdfParseable

  included do
    field :map_resources, type: Array, default: []
    before_save :save_map_resources
  end

  private

  def save_map_resources
    self.map_resources = []

    return if file.nil?
    return if source_url.present?

    if tsv_present?
      save_map_resources_from_tsv
    elsif xls_present?
      save_map_resources_from_xls
    end
  rescue => e
    logger.error("Opendata Resource save_map_resources failed : #{e.class} (#{e.message})")
  end

  def save_map_resources_from_tsv
    Timeout.timeout(20) do
      csv = parse_tsv
      points = extract_map_points(csv)
      if points.present?
        self.map_resources << { sheet: "1", map_points: points }
      end
    end
  end

  def save_map_resources_from_xls
    sp = nil
    Timeout.timeout(20) do
      sp = Roo::Spreadsheet.open(file.path, extension: format.downcase.to_sym)
    end

    sp.sheets.each_with_index do|sheet, page|
      Timeout.timeout(10) do
        csv = CSV.parse(sp.sheet(page).to_csv)
        points = extract_map_points(csv)
        if points.present?
          self.map_resources << { sheet: sheet, map_points: points }
        end
      end
    end
  end

  public

  def previewable?
    tsv_present? || xls_present? || kml_present? || geojson_present? || pdf_present? || image_present?
  end

  def kml_present?
    %w(KML).index(format.to_s.upcase) != nil
  end

  def geojson_present?
    %w(GEOJSON).index(format.to_s.upcase) != nil
  end

  def pdf_present?
    %w(PDF).index(format.to_s.upcase) != nil
  end

  def image_present?
    %w(BMP GIF JPEG JPG PNG).index(format.to_s.upcase) != nil
  end

  def extract_map_points(data)
    return nil if data.blank?

    latitude_header = SS.config.opendata.preview["map"]["latitude_header"]
    longitude_header = SS.config.opendata.preview["map"]["longitude_header"]
    name_header = SS.config.opendata.preview["map"]["name_header"]

    lat_index = nil
    lon_index = nil
    name_index = nil

    header, body = data.partition.with_index { |_, idx| idx == 0 }
    header = header.first

    latitude_header.each do |latitude|
      lat_index = header.index(latitude)
      break if lat_index
    end

    longitude_header.each do |longitude|
      lon_index = header.index(longitude)
      break if lon_index
    end

    name_header.each do |name|
      name_index = header.index(name)
      break if name_index
    end

    return nil if lat_index.nil? || lon_index.nil?

    map_points = []
    body.each do |line|
      next if line[lat_index].blank? || line[lon_index].blank?

      name = name_index ? line[name_index] : ""
      lat = line[lat_index].to_f
      lon = line[lon_index].to_f

      next if lat < -90.0 || lat > 90.0
      next if lon < -180.0 || lat > 180.0

      map_points << { "name" => name, "loc" => [ lat, lon ] }
    end
    map_points
  end
end
