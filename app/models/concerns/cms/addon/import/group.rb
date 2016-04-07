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
      def to_csv
        csv = CSV.generate do |data|
          data << %w(id name order ldap_dn contact_tel contact_fax contact_email)
          criteria.each do |item|
            line = []
            line << item.id
            line << item.name
            line << item.order
            line << item.ldap_dn
            line << item.contact_tel
            line << item.contact_fax
            line << item.contact_email
            data << line
          end
        end
      end
    end

    def import
      @imported = 0
      validate_import
      return false unless errors.empty?

      table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        item = update_row(row, i + 2)
      end
      return errors.empty?
    end

    private
      def validate_import
        return errors.add :in_file, :blank if in_file.blank?

        fname = in_file.original_filename
        return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i
        begin
          table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
          in_file.rewind
        rescue => e
          errors.add :in_file, :invalid_file_type
        end
      end

      def update_row(row, index)
        id            = row["id"].to_s.strip
        name          = row["name"].to_s.strip
        order         = row["order"].to_s.strip
        ldap_dn       = row["ldap_dn"].to_s.strip
        contact_tel   = row["contact_tel"].to_s.strip
        contact_fax   = row["contact_fax"].to_s.strip
        contact_email = row["contact_email"].to_s.strip

        if id.present?
          item = self.class.where(id: id).first
          if item.blank?
            e = I18n.t("errors.messages.not_exist")
            self.errors.add :base, "#{index}: #{t(:id)}#{e}"
            return nil
          end

          if name.blank?
            item.destroy
            @imported += 1
            return nil
          end
        else
          item = self.class.new
        end

        item.name          = name
        item.order         = order
        item.ldap_dn       = ldap_dn
        item.contact_tel   = contact_tel
        item.contact_fax   = contact_fax
        item.contact_email = contact_email

        if item.save
          @imported += 1
        else
          set_errors(item, index)
        end
        item
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
