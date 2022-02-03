module Member::Addon
  module LineAttributes
    extend SS::Addon
    extend ActiveSupport::Concern

    CHILD_MAX_SIZE = 5

    included do
      field :first_registered, type: DateTime
      field :subscribe_line_message, type: String, default: "active"
      embeds_ids :deliver_categories, class_name: "Cms::Line::DeliverCategory::Category"
      field :subscribe_richmenu_id, type: String

      validates :subscribe_line_message, inclusion: { in: %w(active expired) }

      permit_params :first_registered, :subscribe_richmenu_id, :subscribe_line_message
      permit_params deliver_category_ids: []

      1.upto(CHILD_MAX_SIZE) do |i|
        field :"child#{i}_name", type: String
        field :"child#{i}_birthday", type: Date
        attr_accessor :"in_child#{i}_birth"

        permit_params :"in_child#{i}_birth" => [:era, :year, :month, :day]
        permit_params :"child#{i}_name"
        validate :"set_child#{i}_birthday"
      end
    end

    def each_deliver_categories
      Cms::Line::DeliverCategory::Category.site(site).each_public do |root, children|
        categories = children.select { |child| deliver_category_ids.include?(child.id) }
        yield(root, categories) if categories.present?
      end
    end

    def deliver_category_conditions
      @_deliver_category_conditions ||= begin
        cond = []
        each_deliver_categories do |root, children|
          st_category_ids = children.map(&:st_category_ids).flatten
          st_category_ids << -1 if st_category_ids.blank?
          cond << { category_ids: { "$in" => st_category_ids } }
        end
        cond.present? ? { "$and" => cond } : { id: -1 }
      end
    end

    def deliver_child_ages
      @_deliver_child_ages ||= begin
        items = []
        child_ages = Cms::Line::DeliverCategory::ChildAge.site(site).to_a
        1.upto(CHILD_MAX_SIZE) do |i|
          name = send("child#{i}_name")
          age = send("child#{i}_age")
          next if name.blank?

          item = { name: name, child_ages: [] }
          child_ages.each do |child_age|
            next if !child_age.condition_ages.include?(age)
            item[:child_ages] << child_age
          end
          items << item
        end
        items
      end
    end

    def subscribe_line_message_options
      %w(active expired).map { |m| [ I18n.t("member.options.subscribe_line_message.#{m}"), m ] }.to_a
    end

    def calculate_age(today, birthday)
      return if birthday > today

      # year
      d1 = format("%04d%02d%02d", today.year, today.month, today.day).to_i
      d2 = format("%04d%02d%02d", birthday.year, birthday.month, birthday.day).to_i
      d3 = (d1 - d2)
      d3 = format("%08d", (d3 > 0) ? d3 : 0)
      y = d3[0..3].to_i

      # month
      m = today.day >= birthday.day ? today.month : today.advance(months: -1).month
      m = (m >= birthday.month) ? m - birthday.month : (12 - birthday.month) + m
      [y, m]
    end

    def child_ages
      ages = []
      1.upto(CHILD_MAX_SIZE) do |i|
        ages << send("child#{i}_age")
      end
      ages.compact
    end

    def child_birthday_labels
      (1..Cms::Member::CHILD_MAX_SIZE).map { |i| send("child#{i}_birthday_label") }.compact
    end

    1.upto(CHILD_MAX_SIZE) do |i|
      accessor_key = :"in_child#{i}_birth"
      birthday_key = :"child#{i}_birthday"
      name_key = :"child#{i}_name"

      define_method("child#{i}_age") do
        child_birthday = send(birthday_key)
        return if child_birthday.blank?
        calculate_age(Time.zone.today, child_birthday)
      end

      define_method("child#{i}_age_label") do
        y, m = send("child#{i}_age")
        return if !(y && m)
        "#{y}歳#{m}ヶ月"
      end

      define_method("child#{i}_birthday_label") do
        birthday = send(birthday_key)
        return if birthday.blank?
        birthday = I18n.l(birthday.to_date, format: :long)
        age = send("child#{i}_age_label")
        age.present? ? "#{birthday}（#{age}）" : birthday
      end

      define_method("parse_in_child#{i}_birth") do
        in_child_birth = send(accessor_key)
        child_birthday = send(birthday_key)

        era = "seireki"
        if in_child_birth
          year  = in_child_birth["year"]
          month = in_child_birth["month"]
          day   = in_child_birth["day"]
        else
          year  = child_birthday.try(:year)
          month = child_birthday.try(:month)
          day   = child_birthday.try(:day)
        end

        [era, year, month, day]
      end

      define_method("set_child#{i}_birthday") do
        if send(name_key).blank?
          send("#{birthday_key}=", nil)
          return
        end

        in_child_birth = send(accessor_key)
        return if in_child_birth.blank?

        era = "seireki"
        year = in_child_birth[:year]
        month = in_child_birth[:month]
        day = in_child_birth[:day]

        if year.blank? && month.blank? && day.blank?
          errors.add birthday_key, :empty
          return
        elsif year.blank? || month.blank? || day.blank?
          errors.add birthday_key, :incorrectly
          return
        end

        year = year.to_i
        month = month.to_i
        day = day.to_i

        begin
          wareki = I18n.t("ss.wareki")[era.to_sym]
          min = Date.parse(wareki[:min])
          date = Date.new(min.year + year - 1, month, day)
          send("#{birthday_key}=", date)
        rescue
          errors.add brithday_key, :incorrectly
        end
      end
    end

    def private_show_path(*args)
      options = args.extract_options!
      options.merge!(site: (cur_site || site), id: id)
      helper_mod = Rails.application.routes.url_helpers
      helper_mod.cms_member_path(*args, options) rescue nil
    end

    module ClassMethods
      def encode_sjis(str)
        str.encode("SJIS", invalid: :replace, undef: :replace)
      end

      def line_members_enum(site)
        members = criteria.to_a

        roots = []
        category_ids = []
        Cms::Line::DeliverCategory::Category.site(site).each_public do |root, children|
          roots << root
          category_ids << children.map(&:id)
        end

        Enumerator.new do |y|
          headers = %w(id name oauth_id child_ages).map { |v| self.t(v) }
          headers += roots.map(&:name)
          y << encode_sjis(headers.to_csv)
          members.each do |item|
            row = []
            row << item.id
            row << item.name
            row << item.oauth_id
            row << item.child_birthday_labels.join("\n")
            category_ids.each do |ids|
              row << item.deliver_categories.select { |category| ids.include?(category.id) }.map(&:name).join("\n")
            end
            y << encode_sjis(row.to_csv)
          end
        end
      end
    end
  end
end
