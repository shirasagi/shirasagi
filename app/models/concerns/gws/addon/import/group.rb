require "csv"

module Gws::Addon::Import
  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        %w(id name domains order ldap_dn group_code activation_date expiration_date superior_group_ids)
      end

      def to_csv
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            line = []
            line << item.id
            line << item.name
            line << item.domains
            line << item.order
            line << item.ldap_dn
            line << item.group_code
            line << (item.activation_date.present? ? I18n.l(item.activation_date) : nil)
            line << (item.expiration_date.present? ? I18n.l(item.expiration_date) : nil)
            line << item.superior_groups.pluck(:name).join("\n")
            data << line
          end
        end
      end
    end

    def import
      @imported = 0
      validate_import
      return false unless errors.empty?

      SS::Csv.foreach_row(in_file, headers: true) do |row, i|
        update_row(row, i + 2)
      end
      return errors.empty?
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
      id              = row[t("id")].to_s.strip
      name            = row[t("name")].to_s.strip
      domains         = row[t("domains")].to_s.strip
      order           = row[t("order")].to_s.strip
      ldap_dn         = row[t("ldap_dn")].to_s.strip
      group_code      = row[t("group_code")].to_s.strip
      activation_date = row[t("activation_date")].to_s.strip
      expiration_date = row[t("expiration_date")].to_s.strip
      superior_groups = row[t("superior_group_ids")].to_s.strip.split(/\r\n|\n/)
      superior_groups = Gws::Group.active.in(name: superior_groups).to_a

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

      item.name               = name
      item.order              = order
      item.domains            = domains
      item.ldap_dn            = ldap_dn
      item.group_code         = group_code
      item.activation_date    = activation_date
      item.expiration_date    = expiration_date
      item.superior_group_ids = superior_groups.map(&:id)

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
