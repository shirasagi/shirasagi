require "csv"

module Cms::Addon::Import
  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        %w(
          id name order ldap_dn contact_tel contact_fax contact_email contact_link_url
          contact_link_name activation_date expiration_date
        )
      end

      def to_csv
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            line = []
            line << item.id
            line << item.name
            line << item.order
            line << item.ldap_dn
            line << item.contact_tel
            line << item.contact_fax
            line << item.contact_email
            line << item.contact_link_url
            line << item.contact_link_name
            line << (item.activation_date.present? ? I18n.l(item.activation_date) : nil)
            line << (item.expiration_date.present? ? I18n.l(item.expiration_date) : nil)
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
      id             = row[t("id")].to_s.strip
      name           = row[t("name")].to_s.strip
      order          = row[t("order")].to_s.strip
      ldap_dn        = row[t("ldap_dn")].to_s.strip
      contact_tel    = row[t("contact_tel")].to_s.strip
      contact_fax    = row[t("contact_fax")].to_s.strip
      contact_email  = row[t("contact_email")].to_s.strip
      contact_link_url = row[t("contact_link_url")].to_s.strip
      contact_link_name = row[t("contact_link_name")].to_s.strip
      activation_date = row[t("activation_date")].to_s.strip
      expiration_date = row[t("expiration_date")].to_s.strip

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

      item.name            = name
      item.order           = order
      item.ldap_dn         = ldap_dn
      item.contact_tel     = contact_tel
      item.contact_fax     = contact_fax
      item.contact_email   = contact_email
      item.contact_link_url = contact_link_url
      item.contact_link_name = contact_link_name
      item.activation_date = activation_date
      item.expiration_date = expiration_date

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
