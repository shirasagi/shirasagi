require "csv"

module Gws::Addon::Import
  module Role
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        headers = %w(id name permissions)
        unless SS.config.ss.disable_permission_level
          headers << 'permission_level'
        end
        headers
      end

      def to_csv
        I18n.with_locale(I18n.default_locale) do
          CSV.generate do |data|
            data << csv_headers.map { |k| t k }
            criteria.each do |item|
              line = []
              line << item.id
              line << item.name
              line << item.localized_permissions.join("\n")
              unless SS.config.ss.disable_permission_level
                line << item.permission_level
              end
              data << line
            end
          end
        end
      end
    end

    def import
      @imported = 0
      validate_import
      return false unless errors.empty?

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.foreach_row(in_file, headers: true) do |row, i|
          update_row(row, i + 2)
        end
      end
      return errors.empty?
    end

    def localized_permissions
      localized = []
      self._module_permission_names.each do |mod, names|
        names.each do |name|
          next unless self.permissions.include? name.to_s
          localized.push "[#{self.class.mod_name(mod)}]#{I18n.t("#{self.collection_name.to_s.singularize}.#{name}")}"
        end
      end
      localized
    end

    def normalized_permissions(localized)
      normalized = []
      self.class.module_permission_names(separator: true).each do |mod, names|
        names.each do |name|
          permission = "[#{self.class.mod_name(mod)}]#{I18n.t("#{self.collection_name.to_s.singularize}.#{name}")}"
          next unless localized.include? permission
          normalized << name.to_s
        end
      end
      normalized
    end

    private

    def validate_import
      return errors.add :in_file, :blank if in_file.blank?
      return errors.add :cur_site, :blank if cur_site.blank?

      fname = in_file.original_filename
      unless /^\.csv$/i.match?(::File.extname(fname))
        errors.add :in_file, :invalid_file_type
        return
      end

      errors.add :in_file, :invalid_file_type if !SS::Csv.valid_csv?(in_file, headers: true)
      in_file.rewind
    end

    def update_row(row, index)
      id               = row[t("id")].to_s.strip
      name             = row[t("name")].to_s.strip
      permissions      = row[t("permissions")].to_s.strip.split("\n")
      permission_level = row[t("permission_level")].to_s.strip.to_i

      if id.present?
        item = self.class.unscoped.site(cur_site).where(id: id).first
        if item.blank?
          self.errors.add :base, :not_found, line_no: index, id: id
          return nil
        end

        if name.blank?
          item.disable
          @imported += 1
          return nil
        end
      else
        item = self.class.new
      end

      item.name             = name
      item.permissions      = item.normalized_permissions(permissions)
      item.permission_level = (permission_level == 0) ? 1 : permission_level
      item.site_id          = cur_site.id

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def set_errors(item, index)
      SS::Model.copy_errors(item, self, prefix: "#{index}: ")
    end
  end
end
