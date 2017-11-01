require "csv"

module Gws::Addon::Import
  module User
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported
      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        %w(
          id name kana uid organization_uid email password tel tel_ext title_ids account_start_date account_expiration_date
          initial_password_warning organization_id groups gws_main_group_ids switch_user_id
          ldap_dn gws_roles
        )
      end

      def to_csv(opts = {})
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            roles = item.gws_roles
            roles = roles.site(opts[:site]) if opts[:site]
            title = item.title(opts[:site])
            main_group = item.gws_main_group_ids.present? ? item.gws_main_group(opts[:site]) : nil
            switch_user = item.switch_user
            line = []
            line << item.id
            line << item.name
            line << item.kana
            line << item.uid
            line << item.organization_uid
            line << item.email
            line << nil
            line << item.tel
            line << item.tel_ext
            line << (title ? title.name : nil)
            line << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
            line << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
            if item.initial_password_warning.present?
              line << I18n.t('ss.options.state.enabled')
            else
              line << I18n.t('ss.options.state.disabled')
            end
            line << (item.organization ? item.organization.name : nil)
            line << item.groups.map(&:name).join("\n")
            line << (main_group ? main_group.name : nil)
            line << (switch_user ? "#{switch_user.id},#{switch_user.name}" : nil)
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
      id = row[t("id")].to_s.strip
      email = row[t("email")].to_s.strip
      uid = row[t("uid")].to_s.strip

      if id.present?
        item = self.class.unscoped.where(id: id).first
        if item.blank?
          self.errors.add :base, :not_found, line_no: index, id: id
          return nil
        end

        if email.blank? && uid.blank?
          item.disable
          @imported += 1
          return nil
        end
      else
        item = self.class.new
      end

      %w(
        name kana uid email tel tel_ext account_start_date account_expiration_date ldap_dn
      ).each do |k|
        item[k] = row[t(k)].to_s.strip
      end

      # password
      password = row[t("password")].to_s.strip
      item.in_password = password if password.present?

      # groups
      groups = row[t("groups")].to_s.strip.split(/\n/)
      item.group_ids = SS::Group.in(name: groups).map(&:id)

      # gws_roles
      gws_roles = row[t("gws_roles")].to_s.strip.split(/\n/)
      add_gws_roles(item, gws_roles)

      # initial_password_warning
      initial_password_warning = row[t("initial_password_warning")].to_s.strip
      if initial_password_warning == I18n.t('ss.options.state.enabled')
        item.initial_password_warning = 1
      else
        item.initial_password_warning = nil
      end

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def add_gws_roles(item, gws_roles)
      site_role_ids = Cms::Role.site(@cur_site).map(&:id)
      add_role_ids = Cms::Role.site(@cur_site).in(name: gws_roles).map(&:id)
      item.gws_role_ids = item.gws_role_ids - site_role_ids + add_role_ids
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
