module Rss::Addon::Page
  module WeatherXml
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :event_id, type: String
      permit_params :event_id

      # backward compatibility
      alias_method :xml, :weather_xml
    end

    def weather_xml_path
      private_file("#{id}_weather.xml.gz")
    end

    def weather_xml
      if persisted?
        weather_xml_path.tap do |path|
          if ::File.exists?(path)
            return Zlib::GzipReader.open(path) { |gz| gz.read }
          end
        end
      end

      return self[:xml] if self[:xml].present?

      nil
    end

    def save_weather_xml(xml)
      raise "save itself first and then save weather xml" unless persisted?

      weather_xml_path.tap do |path|
        dir = ::File.dirname(path)
        ::FileUtils.mkdir_p(dir) unless ::Dir.exists?(dir)

        Zlib::GzipWriter.open(path) do |gz|
          gz.write(xml)
        end
      end
    end
  end
end
