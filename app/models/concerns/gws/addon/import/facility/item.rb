require "csv"

module Gws::Addon::Import::Facility
  module Item
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Scope::ActivationDate

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def to_csv
        I18n.with_locale(I18n.default_locale) do
          CSV.generate do |data|
            data << csv_headers.map { |k| header_value_to_text(k) }
            criteria.each do |item|
              line = []
              line << item.id
              line << item.name
              add_category(line, item)
              line << item.order
              line << item.min_minutes_limit
              line << item.max_minutes_limit
              line << item.max_days_limit
              line << datetime_to_text(item.reservation_start_date)
              line << datetime_to_text(item.reservation_end_date)
              line << datetime_to_text(item.activation_date)
              line << datetime_to_text(item.expiration_date)
              line << approval_check_state_datas_value_to_text(item.approval_check_state)
              line << update_approved_state_datas_value_to_text(item.update_approved_state)
              line << type_datas_value_to_text(item.text_type)
              line << item.text
              attrs = %i(
                id
                class_name
                name
                order
                required
                tooltips
                prefix_label
                postfix_label
                input_type
                min_decimal
                max_decimal
                initial_decimal
                scale
                minus_type
                max_length
                place_holder
                additional_attr
                select_options
                upload_file_count
              )

              columns_max.times do |i|
                attrs.each do |attr|
                  line << output_line(attr, item.columns[i])
                end
              end
              line << item.reservable_group_names.join("\n")
              line << item.reservable_member_names.join("\n")
              line << readable_setting_range_datas_value_to_text(item.readable_setting_range)
              line << item.readable_group_names.join("\n")
              line << item.readable_member_names.join("\n")
              line << item.group_names.join("\n")
              line << item.user_names.join("\n")
              line << item.permission_level
              data << line
            end
          end
        end
      end

      def csv_headers
        headers = %w(
          id name category_id order min_minutes_limit max_minutes_limit
          max_days_limit reservation_start_date reservation_end_date
          activation_date expiration_date approval_check_state update_approved_state
          type html
        )
        headers += columns_headers
        headers += %w(
          reservable_group_names reservable_member_names readable_setting_range
          readable_group_names readable_member_names group_names user_names permission_level
        )
        headers
      end

      def columns_max
        criteria.map(&:columns).map(&:size).max.to_i
      end

      def columns_headers
        headers = %i(
          id
          type
          name
          order
          required
          tooltips
          prefix_label
          postfix_label
          input_type
          min_decimal
          max_decimal
          initial_decimal
          scale
          minus_type
          max_length
          place_holder
          additional_attr
          select_options
          upload_file_count
        )

        columns_max.times.flat_map do |i|
          headers.map do |header|
            ["columns.#{header}", n: i + 1]
          end
        end
      end

      def output_line(attr, record)
        return if record.blank?
        return if !record.respond_to?(attr)
        case attr
        when :input_type
          I18n.t("gws/facility/item.csv.columns.input_type_datas.#{record.send(attr)}")
        when :required
          I18n.t("gws/facility/item.csv.columns.required_datas.#{record.send(attr)}")
        when :minus_type
          I18n.t("gws/facility/item.csv.columns.minus_type_datas.#{record.send(attr)}")
        when :class_name
          record.class.model_name.human
        when :select_options
          record.send(attr).join("\n")
        else
          record.send(attr)
        end
      end

      def add_category(line, item)
        return line << item.category.name if item.category.present?
        line << nil
      end

      def datetime_to_text(time)
        return if time.blank?
        I18n.l(time)
      end

      def header_value_to_text(header, **options)
        I18n.t("gws/facility/item.csv.#{header}", **options)
      end

      def type_datas_value_to_text(type_datas)
        return if type_datas.blank?
        I18n.t("gws/facility/item.csv.type_datas.#{type_datas}")
      end

      def approval_check_state_datas_value_to_text(approval_check_state)
        return if approval_check_state.blank?
        I18n.t("gws/facility/item.csv.approval_check_state_datas.#{approval_check_state}")
      end

      def update_approved_state_datas_value_to_text(update_approved_state)
        return if update_approved_state.blank?
        I18n.t("gws/facility/item.csv.update_approved_state_datas.#{update_approved_state}")
      end

      def readable_setting_range_datas_value_to_text(readable_setting_range)
        return if readable_setting_range.blank?
        I18n.t("gws/facility/item.csv.readable_setting_range_datas.#{readable_setting_range}")
      end
    end

    def import
      @imported = 0
      validate_import
      return false unless errors.empty?

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.foreach_row(in_file, headers: true) do |row, i|
          update_row(row, i + 2)
        end
      end
      errors.blank?
    end

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
      id = row[header_t("id")].to_s.strip
      name = row[header_t("name")].to_s.strip
      category_name = row[t("category_id")].to_s.strip
      order = row[header_t("order")].to_s.strip
      min_minutes_limit = row[header_t("min_minutes_limit")].to_s.strip
      max_minutes_limit = row[header_t("max_minutes_limit")].to_s.strip
      max_days_limit = row[header_t("max_days_limit")].to_s.strip
      reservation_start_date = row[header_t("reservation_start_date")].to_s.strip
      reservation_end_date = row[header_t("reservation_end_date")].to_s.strip
      activation_date = row[header_t("activation_date")].to_s.strip
      expiration_date = row[header_t("expiration_date")].to_s.strip
      approval_check_state = row[header_t("approval_check_state")].to_s.strip
      update_approved_state = row[header_t("update_approved_state")].to_s.strip

      reservable_group_names = row[header_t("reservable_group_names")].to_s.strip.split("\n")
      reservable_member_names = row[header_t("reservable_member_names")].to_s.strip.split("\n")
      readable_setting_range = row[header_t("readable_setting_range")].to_s.strip
      readable_group_names = row[header_t("readable_group_names")].to_s.strip.split("\n")
      readable_member_names = row[header_t("readable_member_names")].to_s.strip.split("\n")
      group_names = row[header_t("group_names")].to_s.strip.split("\n")
      user_names = row[header_t("user_names")].to_s.strip.split("\n")
      permission_level = row[header_t("permission_level")].to_s.strip
      text_type = row[header_value_to_text("type")].to_s.strip
      text = row[header_value_to_text("html")].to_s.strip

      if id.present?
        item = self.class.unscoped.site(cur_site).where(id: id).first
        if item.blank?
          self.errors.add :base, :not_found, line_no: index, id: id
          return
        end

        if name.blank?
          item.disable
          @imported += 1
          return
        end
      else
        item = self.class.new
      end
      item.site = @cur_site
      item.user = @cur_user
      item.name = name
      item.category = Gws::Facility::Category.site(@cur_site).where(name: category_name).first
      item.order = order
      item.min_minutes_limit = min_minutes_limit
      item.max_minutes_limit = max_minutes_limit
      item.max_days_limit = max_days_limit
      item.reservation_start_date = reservation_start_date
      item.reservation_end_date = reservation_end_date
      item.activation_date = activation_date
      item.expiration_date = expiration_date

      item.reservable_group_ids = group_names_to_ids(reservable_group_names)
      item.reservable_member_ids = user_names_to_ids(reservable_member_names)

      item.readable_setting_range = readable_setting_range_datas_text_to_value(readable_setting_range)

      item.text_type = type_datas_text_to_value(text_type)
      item.text = text

      item.readable_group_ids = group_names_to_ids(readable_group_names)
      item.readable_member_ids = user_names_to_ids(readable_member_names)
      item.group_ids = group_names_to_ids(group_names)
      item.user_ids = user_names_to_ids(user_names)
      item.permission_level = permission_level

      item.approval_check_state = approval_check_state_datas_text_to_value(approval_check_state)
      item.update_approved_state = update_approved_state_datas_text_to_value(update_approved_state)
      if item.save
        @imported += 1
        @cur_form = item
        set_errors(item, index) unless update_columns(row, index, item)
      else
        set_errors(item, index)
      end
    end

    def set_errors(item, index)
      SS::Model.copy_errors(item, self, prefix: "#{index}: ")
    end

    def header_t(header, **options)
      I18n.t("gws/facility/item.csv.#{header}", **options)
    end

    def user_names_to_ids(names)
      user_names = names.map do |name|
        name.gsub(/ \(.+\)\z/, "")
      end
      Gws::User.any_in(name: user_names).pluck(:id)
    end

    def group_names_to_ids(names)
      Gws::Group.any_in(name: names).pluck(:id)
    end

    def update_columns(row, index, item)
      columns_setting = I18n.t("modules.addons.gws/facility/column_setting")

      column_with_index = row.select { |header_key, _v| header_key =~ /\A#{columns_setting}/ }.to_h
      column_with_index = column_with_index.group_by do |k, v|
        k =~ /\A#{columns_setting}([0-9]+)/
        $1
      end

      datas = column_with_index.each_with_object({}) do |(key, value), hash|
        hash[key] = value.each_with_object({}) do |(k, v), h|
          text_key, _text_value = I18n.t("gws/facility/item.csv.columns").find do |key, value|
            k.match(value.gsub("%{n}", "[0-9]+"))
          end
          h[text_key] = v
        end
      end
      errors = []
      datas.each do |key, value|
        next if value.values.none?
        add_data_by_type(key, value, errors)
      end
      return true if errors.blank?
      columns_set_errors(item, errors)
      false
    end

    def add_data_by_type(key, value, errors)
      if value[:id].present?
        column = Gws::Column::Base.unscoped.site(cur_site).where(id: value[:id]).first
        if column.blank?
          column = Gws::Column::Base.new
          column.errors.add :id, :not_found, id: value[:id]
          create_column_errors(errors, key, column)
          return
        end

        if value[:name].blank?
          column.destroy
          @imported += 1
          return
        end
      else
        column = column_model(value[:type]).new
      end

      case column
      when Gws::Column::TextField
        column.input_type = input_type_datas_text_to_value(value[:input_type].to_s.strip)
        column.max_length = value[:max_length].to_s.strip
        column.additional_attr = value[:additional_attr].to_s.strip
        column.place_holder = value[:place_holder].to_s.strip
      when Gws::Column::DateField
        column.input_type = input_type_datas_text_to_value(value[:input_type].to_s.strip)
        column.place_holder = value[:place_holder].to_s.strip
      when Gws::Column::UrlField
        column.max_length = value[:max_length].to_s.strip
        column.additional_attr = value[:additional_attr].to_s.strip
        column.place_holder = value[:place_holder].to_s.strip
      when Gws::Column::NumberField
        column.min_decimal = value[:min_decimal].to_s.strip
        column.max_decimal = value[:max_decimal].to_s.strip
        column.initial_decimal = value[:initial_decimal].to_s.strip
        column.scale = value[:scale].to_s.strip
        column.minus_type = minus_type_datas_text_to_value(value[:minus_type].to_s.strip)
        column.max_length = value[:max_length].to_s.strip
        column.additional_attr = value[:additional_attr].to_s.strip
        column.place_holder = value[:place_holder].to_s.strip
      when Gws::Column::TextArea
        column.max_length = value[:max_length].to_s.strip
        column.additional_attr = value[:additional_attr].to_s.strip
        column.place_holder = value[:place_holder].to_s.strip
      when Gws::Column::Select
        column.select_options = value[:select_options].to_s.strip.split("\n")
        column.place_holder = value[:place_holder].to_s.strip
      when Gws::Column::RadioButton
        column.select_options = value[:select_options].to_s.strip.split("\n")
      when Gws::Column::CheckBox
        column.select_options = value[:select_options].to_s.strip.split("\n")
      when Gws::Column::FileUpload
        column.upload_file_count = value[:upload_file_count].to_s.strip
        column.place_holder = value[:place_holder].to_s.strip
      end

      column.site = @cur_site
      column.form = @cur_form
      column.name = value[:name].to_s.strip
      column.order = value[:order].to_s.strip
      column.required = value[:require].to_s.strip
      column.tooltips = value[:tooltips].to_s.strip
      column.prefix_label = value[:prefix_label].to_s.strip
      column.postfix_label = value[:postfix_label].to_s.strip

      column.required = required_datas_text_to_value(value[:required].to_s.strip)
      if column.save
        @imported += 1
      else
        create_column_errors(errors, key, column)
      end
    end

    def column_model(type)
      return if type.blank?
      type_text_to_value(type).sub('/', '/column/').classify.constantize
    end

    def type_text_to_value(text)
      return if text.blank?
      k, _v = I18n.t("gws.columns").find do |key, value|
        text.match(value)
      end
      k.to_s
    end

    def input_type_datas_text_to_value(text)
      k, _v = I18n.t("gws/facility/item.csv.columns.input_type_datas").find do |key, value|
        text.match(value)
      end
      k.to_s
    end

    def required_datas_text_to_value(text)
      k, _v = I18n.t("gws/facility/item.csv.columns.required_datas").find do |key, value|
        text.match(value)
      end
      k.to_s
    end

    def minus_type_datas_text_to_value(text)
      k, _v = I18n.t("gws/facility/item.csv.columns.minus_type_datas").find do |key, value|
        text.match(value)
      end
      k.to_s
    end

    def header_value_to_text(header)
      I18n.t("gws/facility/item.csv.#{header}")
    end

    def column_header_value_to_text(header, **options)
      I18n.t("gws/facility/item.csv.columns.#{header}", **options)
    end

    def approval_check_state_datas_text_to_value(approval_check_state_datas)
      k, _v = I18n.t("gws/facility/item.csv.approval_check_state_datas").find do |key, value|
        approval_check_state_datas.match(value)
      end
      k.to_s
    end

    def update_approved_state_datas_text_to_value(update_approved_state_datas)
      k, _v = I18n.t("gws/facility/item.csv.update_approved_state_datas").find do |key, value|
        update_approved_state_datas.match(value)
      end
      k.to_s
    end

    def readable_setting_range_datas_text_to_value(readable_setting_range_datas)
      k, _v = I18n.t("gws/facility/item.csv.readable_setting_range_datas").find do |key, value|
        readable_setting_range_datas.match(value)
      end
      k.to_s
    end

    def type_datas_text_to_value(text)
      k, _v = I18n.t("gws/facility/item.csv.type_datas").find do |key, value|
        text.match(value)
      end
      k.to_s
    end

    def disable
      super
      columns.each(&:destroy)
    end

    def create_column_errors(errors, key, column)
      column.errors.messages.map do |n, e|
        errors << "#{column_header_value_to_text(n, n: key)}#{e[0]}"
      end
    end

    def columns_set_errors(item, errors)
      item.errors.add :base, errors.join(" ").to_s
    end
  end
end
