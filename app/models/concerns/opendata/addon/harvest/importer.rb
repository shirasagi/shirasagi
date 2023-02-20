module Opendata::Addon::Harvest
  module Importer
    extend SS::Addon
    extend ActiveSupport::Concern
    include Opendata::Harvest::CkanApiImporter
    include Opendata::Harvest::ShirasagiApiImporter
    include Opendata::Harvest::ShirasagiScrapingImporter

    EXTERNAL_RESOUCE_FORMAT = %w(html htm).freeze

    def import
      if !enabled?
        put_log("not enabled #{source_url}")
        return
      end

      if api_type == "ckan"
        import_from_ckan_api
      elsif api_type == "shirasagi_api"
        import_from_shirasagi_api
      elsif api_type == "shirasagi_scraper"
        import_from_shirasagi_scraper
      end
    end

    def destroy_imported_datasets
      dataset_ids = ::Opendata::Dataset.site(site).node(node).where("$or" => [
          { harvest_api_type: api_type, harvest_host: source_host },
          { harvest_importer_id: id }
      ]).pluck(:id)

      put_log("datasets #{dataset_ids.size}")
      dataset_ids.each do |id|
        dataset = ::Opendata::Dataset.find(id) rescue nil
        next unless dataset

        put_log("- dataset : destroy #{dataset.name}")
        dataset.destroy
      end
    end

    private

    def put_log(message)
      Rails.logger.warn(message)
      puts message
    end

    def get_license_from_uid(uid)
      @_license_from_uid ||= {}
      return @_license_from_uid[uid] if @_license_from_uid[uid]

      @_license_from_uid[uid] = ::Opendata::License.site(site).where(uid: uid).first
      @_license_from_uid[uid]
    end

    def get_license_from_name(name)
      @_license_from_name ||= {}
      return @_license_from_name[name] if @_license_from_name[name]

      @_license_from_name[name] = ::Opendata::License.site(site).where(name: name).first
      @_license_from_name[name]
    end

    def set_relation_ids(dataset)
      # category
      @_category_settings ||= begin
        h = {}
        category_settings.each do |setting|
          next if setting.category.nil?

          h[setting.category_id] ||= []
          h[setting.category_id] << setting
        end
        h
      end

      category_ids = []
      @_category_settings.each do |category_id, settings|
        settings.each do |setting|
          if setting.match?(dataset)
            category_ids << category_id
            break
          end
        end
      end
      category_ids = self.default_category_ids if category_ids.blank?
      dataset.category_ids = category_ids

      # estat category
      @_estat_category_settings ||= begin
        h = {}
        estat_category_settings.each do |setting|
          next if setting.category.nil?

          h[setting.category_id] ||= []
          h[setting.category_id] << setting
        end
        h
      end

      estat_category_ids = []
      @_estat_category_settings.each do |category_id, settings|
        settings.each do |setting|
          if setting.match?(dataset)
            estat_category_ids << category_id
            break
          end
        end
      end
      estat_category_ids = self.default_estat_category_ids if estat_category_ids.blank?
      dataset.estat_category_ids = estat_category_ids

      # area
      dataset.area_ids = self.default_area_ids

      message = "- "
      message += "set category_ids #{dataset.category_ids.join(", ")} "
      message += "estat_category_ids #{dataset.estat_category_ids.join(", ")} "
      message += "area_ids #{dataset.area_ids.join(", ")}"
      put_log(message)

      def dataset.set_updated; end
      dataset.save!
      dataset
    end

    def external_resouce?(url, format)
      return true if EXTERNAL_RESOUCE_FORMAT.include?(format.downcase)

      uri = ::Addressable::URI.parse(url)
      if uri.hostname.nil?
        return false
      elsif uri.hostname == self.source_host
        return false
      else
        return true
      end
    rescue => e
      put_log("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      false
    end
  end
end
