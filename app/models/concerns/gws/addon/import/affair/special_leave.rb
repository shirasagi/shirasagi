require "csv"

module Gws::Addon::Import::Affair
  module SpecialLeave
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        %w(id code name order staff_category)
      end

      def to_csv
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            line = []
            line << item.id
            line << item.code
            line << item.name
            line << item.order
            line << item.label(:staff_category)
            data << line
          end
        end
      end
    end

    def import
      @imported = 0
      validate_import
      return false unless errors.empty?

      I18n.with_locale(I18n.default_locale) do
        table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
        table.each_with_index do |row, i|
          update_row(row, i + 2)
        end
      end
      errors.empty?
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

      begin
        CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
        in_file.rewind
      rescue => e
        errors.add :in_file, :invalid_file_type
      end
    end

    def update_row(row, index)
      id               = row[t("id")].to_s.strip
      code             = row[t("code")].to_s.strip
      name             = row[t("name")].to_s.strip
      order            = row[t("order")].to_s.strip
      staff_category   = row[t("staff_category")].to_s.strip

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

      staff_category_h = staff_category_options.to_h

      item.site             = @cur_site
      item.user             = @cur_user
      item.code             = code
      item.name             = name
      item.order            = order
      item.staff_category   = staff_category_h[staff_category]

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def user_names_to_ids(names)
      user_names = names.map do |name|
        name.gsub(/ \(.+\)\z/, "")
      end
      Gws::User.any_in(name: user_names).pluck(:id)
    end

    def group_names_to_ids(names)
      Gws::Group.any_in(name: names).pluck(:id)
    end

    def set_errors(item, index)
      error = ""
      item.errors.each do |n, e|
        error += "#{item.class.t(n)}#{e} "
      end
      self.errors.add :base, "#{index}: #{error}"
    end
  end
end
