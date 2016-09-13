require "csv"

module Cms::Addon::Import
  module User
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported
      permit_params :in_file
    end

    module ClassMethods
      def to_csv(opts = {})
        CSV.generate do |data|
          data << %w(
            id name kana uid email password tel tel_ext account_start_date account_expiration_date
            initial_password_warning groups ldap_dn cms_roles)
          criteria.each do |item|
            roles = item.cms_roles
            roles = roles.site(opts[:site]) if opts[:site]
            line = []
            line << item.id
            line << item.name
            line << item.kana
            line << item.uid
            line << item.email
            line << nil
            line << item.tel
            line << item.tel_ext
            line << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
            line << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
            line << item.initial_password_warning
            line << item.groups.map(&:name).join("\n")
            line << item.ldap_dn
            line << roles.map(&:name).join("\n")
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
        update_row(row, i + 2)
      end
      return errors.empty?
    end

    private
      def validate_import
        return errors.add :in_file, :blank if in_file.blank?

        fname = in_file.original_filename
        return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i
        begin
          CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
          in_file.rewind
        rescue => e
          errors.add :in_file, :invalid_file_type
        end
      end

      def update_row(row, index)
        id                       = row["id"].to_s.strip
        name                     = row["name"].to_s.strip
        kana                     = row["kana"].to_s.strip
        uid                      = row["uid"].to_s.strip
        email                    = row["email"].to_s.strip
        password                 = row["password"].to_s.strip
        tel                      = row["tel"].to_s.strip
        tel_ext                  = row["tel_ext"].to_s.strip
        account_start_date       = row["account_start_date"].to_s.strip
        account_expiration_date  = row["account_expiration_date"].to_s.strip
        initial_password_warning = row["initial_password_warning"].to_s.strip
        groups                   = row["groups"].to_s.strip.split(/\n/)
        ldap_dn                  = row["ldap_dn"].to_s.strip
        cms_roles                = row["cms_roles"].to_s.strip.split(/\n/)

        if id.present?
          item = self.class.unscoped.where(id: id).first
          if item.blank?
            self.errors.add :base, :not_found, line_no: index, id: id
            return nil
          end

          if email.blank? && uid.blank?
            item.destroy
            @imported += 1
            return nil
          end
        else
          item = self.class.new
        end

        item.name = name
        item.kana = kana
        item.uid = uid
        item.email = email
        item.in_password = password if password.present?
        item.tel = tel
        item.tel_ext = tel_ext
        item.account_start_date = account_start_date
        item.account_expiration_date = account_expiration_date
        item.initial_password_warning = initial_password_warning
        item.group_ids = SS::Group.in(name: groups).map(&:id)
        item.ldap_dn = ldap_dn
        add_cms_roles(item, cms_roles)
        if item.save
          @imported += 1
        else
          set_errors(item, index)
        end
        item
      end

      def add_cms_roles(item, cms_roles)
        site_role_ids = Cms::Role.site(@cur_site).map(&:id)
        add_role_ids = Cms::Role.site(@cur_site).in(name: cms_roles).map(&:id)
        item.cms_role_ids = item.cms_role_ids - site_role_ids + add_role_ids
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
