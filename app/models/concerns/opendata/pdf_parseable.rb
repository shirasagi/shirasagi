module Opendata::PdfParseable
  extend ActiveSupport::Concern

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
        Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
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
