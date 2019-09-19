module Opendata::Resource::Previewable
  extend ActiveSupport::Concern
  include Opendata::TsvParseable

  included do
    field :map_resources, type: Array, default: []
    before_save :save_map_resources
  end

  private

  def save_map_resources
    return if file.nil? || source_url.present?
    self.map_resources = []

    if tsv_present?
      csv = parse_tsv
      points = extract_map_points(csv)
      if points.present?
        self.map_resources << { sheet: "1", map_points: points }
      end
    elsif xls_present?
      sp = parse_xls
      if sp
        sp.sheets.each_with_index do |sheet, page|
          Timeout.timeout(10) do
            csv = CSV.parse(sp.sheet(page).to_csv)
          end
          points = extract_map_points(csv)
          if points.present?
            self.map_resources << { sheet: sheet, map_points: points }
          end
        end
      end
    end
  rescue => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
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

  def extract_pdf_base64_images(limit = nil)
    limit ||= SS.config.opendata.preview["pdf"]["page_limit"]

    return [] unless file && pdf_present?

    require 'rmagick'
    images = []
    0.upto(limit - 1) do |n|
      begin
        image = Magick::Image.read(file.path + "[#{n}]") do
          self.quality = 100
          self.density = 200
        end.first
      rescue Magick::ImageMagickError => e
        Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        image = nil
      end

      break if image.blank?
      images << image
    end

    images = images.map do |image|
      image.format = "PNG"
      Base64.strict_encode64(image.to_blob)
    end
    images
  end
end
