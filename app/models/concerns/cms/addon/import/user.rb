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
      def csv_headers
        %w(
          id name kana uid organization_uid email password tel tel_ext account_start_date account_expiration_date
          initial_password_warning organization_id groups ldap_dn cms_roles
        )
      end

      def to_csv(opts = {})
        CSV.generate do |data|
          data << csv_headers.map { |k| t k }
          criteria.each do |item|
            roles = item.cms_roles
            roles = roles.site(opts[:site]) if opts[:site]
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
            line << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
            line << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
            if item.initial_password_warning.present?
              line << I18n.t('ss.options.state.enabled')
            else
              line << I18n.t('ss.options.state.disabled')
            end
            line << item.organization&.name
            line << Cms::Group.site(opts[:site]).in(id: item.group_ids).pluck(:name).join("\n")
            line << item.ldap_dn
            line << roles.pluck(:name).join("\n")
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
        name kana uid organization_uid email tel tel_ext account_start_date account_expiration_date ldap_dn
      ).each do |k|
        item[k] = row[t(k)].to_s.strip
      end

      # password
      password = row[t("password")].to_s.strip
      item.in_password = password.presence

      # organization
      value = row[t('organization_id')].to_s.strip
      group = SS::Group.where(name: value).first if value.present?
      item.organization_id = group&.id

      # groups
      groups = row[t("groups")].to_s.strip.split(/\n/)
      set_group_ids(item, groups)

      # cms_roles
      cms_roles = row[t("cms_roles")].to_s.strip.split(/\n/)
      add_cms_roles(item, cms_roles)

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

    def set_group_ids(item, groups)
      item.group_ids = item.group_ids - rm_group_ids
      if groups.present?
        item.group_ids += SS::Group.in(name: groups).pluck(:id)
      end
      item.imported_group_keys = groups
      item.imported_groups = item.groups
      item.imported_cms_groups = Cms::Group.site(@cur_site)
      item.group_ids = item.group_ids.uniq.sort
    end

    def add_cms_roles(item, cms_roles)
      site_role_ids = Cms::Role.site(@cur_site).pluck(:id)
      add_role_ids = Cms::Role.site(@cur_site).in(name: cms_roles).pluck(:id)
      item.cms_role_ids = item.cms_role_ids - site_role_ids + add_role_ids
    end

    def set_errors(item, index)
      sig = "#{Cms::User.t(:uid)}: #{item.uid}の" if item.uid.present?
      sig ||= "#{Cms::User.t(:email)}: #{item.email}の" if item.email.present?
      sig ||= "#{Cms::User.t(:id)}: #{item.id}の" if item.persisted?
      item.errors.full_messages.each do |error|
        errors.add(:base, "#{index}行目: #{sig}#{error}")
      end
    end

    def rm_group_ids
      @rm_group_ids ||= Cms::Group.site(@cur_site).pluck(:id)
    end
  end
end
