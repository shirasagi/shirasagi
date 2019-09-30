class Gws::UserCsv::Exporter
  include ActiveModel::Model

  attr_accessor :site, :form, :criteria, :encoding, :webmail_support

  PREFIX = 'A:'.freeze

  class << self
    def csv_basic_headers(opts = {})
      headers = %w(
        id name kana uid organization_uid email password tel tel_ext title_ids occupation_ids type
        account_start_date account_expiration_date initial_password_warning session_lifetime
        organization_id groups gws_main_group_ids switch_user_id remark
        ldap_dn staff_category staff_address_uid group_code gws_roles sys_roles
      )
      headers += %w(webmail_roles) if opts[:webmail_support]
      headers.map! { |k| Gws::User.t(k) }
    end

    def csv_headers(opts = {})
      new(opts).csv_headers
    end

    def enum_csv(criteria, opts = {})
      opts = opts.dup
      opts[:criteria] = criteria
      new(opts).enum_csv
    end

    def to_csv(criteria, opts = {})
      enum_csv(criteria, opts).to_a.to_csv
    end
  end

  def csv_extend_headers
    return [] if !site

    cur_form = form || Gws::UserForm.find_for_site(site)
    return [] if !cur_form
    return [] if cur_form.state_closed?

    cur_form.columns.order_by(order: 1, created: 1).map do |column|
      "#{PREFIX}#{column.name}"
    end
  end

  def csv_headers
    self.class.csv_basic_headers(webmail_support: @webmail_support) + csv_extend_headers
  end

  def enum_csv
    form ||= begin
      if site
        Gws::UserForm.find_for_site(site)
      end
    end

    Enumerator.new do |y|
      csv_headers.to_csv.tap do |csv|
        case encoding
        when "Shift_JIS"
          y << encode_sjis(csv)
        when "UTF-8"
          y << SS::Csv::UTF8_BOM + csv
        end
      end
      @criteria.each do |item|
        item_to_csv(item).to_csv.tap do |csv|
          case encoding
          when "Shift_JIS"
            y << encode_sjis(csv)
          when "UTF-8"
            y << csv
          end
        end
      end
    end
  end

  private

  def item_to_csv(item)
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
    terms << item.title(site).try(:code)
    terms << item.occupation(site).try(:code)
    terms << item.label(:type)
    terms << (item.account_start_date.present? ? I18n.l(item.account_start_date) : nil)
    terms << (item.account_expiration_date.present? ? I18n.l(item.account_expiration_date) : nil)
    terms << I18n.t("ss.options.state.#{item.initial_password_warning.present? ? 'enabled' : 'disabled'}")
    terms << item.session_lifetime
    terms << (item.organization ? item.organization.name : nil)
    terms << item.groups.where(name: /\A#{Regexp.escape(root_group_name)}/).pluck(:name).join("\n")
    terms << main_group.try(:name)
    terms << (switch_user ? "#{switch_user.id},#{switch_user.name}" : nil)
    terms << item.remark
    terms << item.ldap_dn
    terms << item.label(:staff_category)
    terms << item.staff_address_uid
    terms << (site ? item.group_code(site) : nil)
    terms << item_roles(item).map(&:name).join("\n")
    terms << item.sys_roles.and_general.map(&:name).join("\n")
    terms << item.webmail_roles.map(&:name).join("\n") if @webmail_support

    terms += item_column_values(item)

    terms
  end

  def item_roles(item)
    roles = item.gws_roles
    roles = roles.site(site) if site
    roles
  end

  def item_column_values(item)
    terms = []

    return terms if !form || form.state_closed?

    form_data = Gws::UserFormData.site(site).user(item).form(form).order_by(id: 1, created: 1).first
    form.columns.order_by(order: 1, created: 1).each do |column|
      column_value = form_data.column_values.where(column_id: column.id).first rescue nil
      terms << column_value.try(:value)
    end

    terms
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def root_group_name
    @root_group_name ||= site.root.name
  end
end