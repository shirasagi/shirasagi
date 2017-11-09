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
      def csv_headers(opts = {})
        headers = %w(
          id name kana uid organization_uid email password tel tel_ext title_ids type
          account_start_date account_expiration_date initial_password_warning session_lifetime
          organization_id groups gws_main_group_ids switch_user_id remark
          ldap_dn gws_roles
        )
        headers.map! { |k| t k }

        site = opts[:site]
        if site
          cur_form = Gws::UserForm.find_for_site(site)
          if cur_form && cur_form.state_public?
            cur_form.columns.each do |column|
              headers << "A:#{column.name}"
            end
          end
        end

        headers
      end

      def enum_csv(opts = {})
        criteria = self.criteria.dup

        site = opts[:site]
        if site
          cur_form = Gws::UserForm.find_for_site(site)
        end

        Enumerator.new do |y|
          y << encode_sjis(csv_headers(opts).to_csv)

          criteria.each do |item|
            terms = item_to_terms(item, site: site, form: cur_form)
            y << encode_sjis(terms.to_csv)
          end
        end
      end

      def to_csv(opts = {})
        enum_csv(copts).to_a.to_csv
      end

      private

      def item_to_terms(item, opts)
        site = opts[:site]

        main_group = item.gws_main_group_ids.present? ? item.gws_main_group(site) : nil
        switch_user = item.switch_user
        terms = []
        terms << item.id
        terms << item.name
        terms << item.kana
        terms << item.uid
        terms << item.organization_uid
        terms << item.email
        terms << nil
        terms << item.tel
        terms << item.tel_ext
        terms << item.title(site).try(:name)
        terms << item.label(:type)
        terms << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
        terms << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
        terms << I18n.t("ss.options.state.#{item.initial_password_warning.present? ? 'enabled' : 'disabled'}")
        terms << item.session_lifetime
        terms << (item.organization ? item.organization.name : nil)
        terms << item.groups.map(&:name).join("\n")
        terms << main_group.try(:name)
        terms << (switch_user ? "#{switch_user.id},#{switch_user.name}" : nil)
        terms << item.remark
        terms << item.ldap_dn
        terms << item_roles(item, site).map(&:name).join("\n")

        terms += item_column_values(item, site, opts[:form])

        terms
      end

      def item_roles(item, site)
        roles = item.gws_roles
        roles = roles.site(site) if site
        roles
      end

      def item_column_values(item, site, cur_form)
        terms = []

        return terms if !cur_form || cur_form.state_closed?

        cur_form_data = Gws::UserFormData.site(site).user(item).form(cur_form).order_by(id: 1, created: 1).first
        cur_form.columns.each do |column|
          column_value = cur_form_data.column_values.where(column_id: column.id).first rescue nil
          terms << column_value.try(:value)
        end

        terms
      end

      def encode_sjis(str)
        str.encode("SJIS", invalid: :replace, undef: :replace)
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
      rescue => e
        errors.add :in_file, :invalid_file_type
      end
      if table.headers != self.class.csv_headers.map { |k| t(k) }
        errors.add :in_file, :invalid_file_type
      end
      in_file.rewind
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
      else
        item = self.class.new
      end

      %w(
        name kana uid organization_uid email tel tel_ext
        account_start_date account_expiration_date session_lifetime remark ldap_dn
      ).each do |k|
        item[k] = row[t(k)].to_s.strip
      end

      site = @cur_site
      item.cur_site = site

      # password
      password = row[t("password")].to_s.strip
      item.in_password = password if password.present?

      # title
      value = row[t("title_ids")].to_s.strip
      title = Gws::UserTitle.site(site).where(name: value).first
      item.in_title_id = title ? title.id : ''

      # type
      value = row[t("type")].to_s.strip
      type = item.type_options.find { |v, k| v == value }
      item.type = type[1] if type

      # initial_password_warning
      initial_password_warning = row[t("initial_password_warning")].to_s.strip
      if initial_password_warning == I18n.t('ss.options.state.enabled')
        item.initial_password_warning = 1
      else
        item.initial_password_warning = nil
      end

      # organization_id
      value = row[t("organization_id")].to_s.strip
      group = SS::Group.where(name: value).first
      item.organization_id = group ? group.id : nil

      # groups
      groups = row[t("groups")].to_s.strip.split(/\n/)
      item.group_ids = SS::Group.in(name: groups).map(&:id)

      # main_group_ids
      value = row[t("gws_main_group_ids")].to_s.strip
      group = SS::Group.where(name: value).first
      item.in_gws_main_group_id = group ? group.id : ''

      # switch_user_id
      value = row[t("switch_user_id")].to_s.strip.split(',', 2)
      user = SS::User.where(id: value[0], name: value[1]).first
      item.switch_user_id = user ? user.id : nil

      # gws_roles
      gws_roles = row[t("gws_roles")].to_s.strip.split(/\n/)
      add_gws_roles(item, gws_roles)

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
    end

    def add_gws_roles(item, gws_roles)
      site_role_ids = Gws::Role.site(@cur_site).map(&:id)
      add_role_ids = Gws::Role.site(@cur_site).in(name: gws_roles).map(&:id)
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
