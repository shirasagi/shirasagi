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
          data << %w(id name email password uid ldap_dn groups cms_roles)
          criteria.each do |item|
            roles = item.cms_roles
            roles = roles.site(opts[:site]) if opts[:site]
            line = []
            line << item.id
            line << item.name
            line << item.email
            line << nil
            line << item.uid
            line << item.ldap_dn
            line << item.groups.map(&:name).join("\n")
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
          table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
          in_file.rewind
        rescue => e
          errors.add :in_file, :invalid_file_type
        end
      end

      def update_row(row, index)
        id        = row["id"].to_s.strip
        email     = row["email"].to_s.strip
        name      = row["name"].to_s.strip
        uid       = row["uid"].to_s.strip
        ldap_dn   = row["ldap_dn"].to_s.strip
        groups    = row["groups"].to_s.strip.split(/\n/)
        cms_roles = row["cms_roles"].to_s.strip.split(/\n/)
        password  = row["password"].to_s.strip

        if id.present?
          item = self.class.where(id: id).first
          if item.blank?
            e = I18n.t("errors.messages.not_exist")
            self.errors.add :base, "#{index}: #{t(:id)}#{e}"
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

        item.email = email
        item.name = name
        item.uid = uid
        item.ldap_dn = ldap_dn
        item.in_password = password if password.present?
        item.group_ids = SS::Group.in(name: groups).map(&:id)
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
