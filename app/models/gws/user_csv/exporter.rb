class Gws::UserCsv::Exporter
  include ActiveModel::Model

  attr_accessor :site
  attr_accessor :form
  attr_accessor :criteria

  class << self
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

  def csv_headers
    headers = %w(
      id name kana uid organization_uid email password tel tel_ext title_ids type
      account_start_date account_expiration_date initial_password_warning session_lifetime
      organization_id groups gws_main_group_ids switch_user_id remark
      ldap_dn gws_roles
    )
    headers.map! { |k| Gws::User.t(k) }

    if site
      cur_form = form || Gws::UserForm.find_for_site(site)
      if cur_form && cur_form.state_public?
        cur_form.columns.order_by(order: 1, created: 1).each do |column|
          headers << "A:#{column.name}"
        end
      end
    end

    headers
  end

  def enum_csv
    form ||= begin
      if site
        Gws::UserForm.find_for_site(site)
      end
    end

    Enumerator.new do |y|
      y << encode_sjis(csv_headers.to_csv)
      @criteria.each do |item|
        y << encode_sjis(item_to_csv(item).to_csv)
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
    terms << item_roles(item).map(&:name).join("\n")

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
end