require "csv"

module Gws::Addon::Import::Schedule
  module Holiday
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported

      permit_params :in_file
    end

    module ClassMethods
      def to_csv
        I18n.with_locale(I18n.default_locale) do
          CSV.generate do |data|
            data << csv_headers.map { |k| header_value_to_text k }
            items = criteria.asc(:repeat_plan_id).group_by { |holiday| holiday[:repeat_plan_id] }
            items.each do |key, values|
              if key.nil?
                values.each do |item|
                  line = []
                  line << item[:id]
                  line += add_line(item)
                  data << line
                end
              else
                item = values.first
                line = []
                line << item[:repeat_plan_id]
                line += add_line(item)
                data << line
              end
            end
          end
        end
      end

      def csv_headers
        %w(id name start_on end_on color
           repeat_plan_datas.repeat_type
           repeat_plan_datas.interval
           repeat_plan_datas.repeat_start
           repeat_plan_datas.repeat_end
           repeat_plan_datas.wdays
           repeat_plan_datas.repeat_base
        )
      end

      def add_line(item)
        line = []
        line << item[:name]
        line << item[:start_on]
        line << item[:end_on]
        line << item[:color]
        attrs = %i(
          repeat_type
          interval
          repeat_start
          repeat_end
          wdays
          repeat_base
        )
        attrs.each_with_index do |attr, i|
          line << output_line(attr, item.repeat_plan, i)
        end
        line
      end

      def output_line(attr, record, index)
        return I18n.t("gws/schedule.options.repeat_type.none") if record.blank? && index.zero?
        return if record.blank?
        return unless record.respond_to?(attr)
        case attr
        when :repeat_type
          I18n.t("gws/schedule.options.repeat_type.#{record.send(attr)}")
        when :wdays
          wdays_value_to_text(record.send(attr)).join(",")
        when :repeat_base
          I18n.t("gws/schedule.options.repeat_base.#{record.send(attr)}")
        when :repeat_start, :repeat_end
          I18n.l(record.send(attr))
        else
          record.send(attr)
        end
      end

      def header_value_to_text(value)
        I18n.t("gws/schedule.csv.#{value}")
      end

      def wdays_value_to_text(values)
        return [] if values.blank?
        values.map do |value|
          I18n.t("date.abbr_day_names")[value]
        end
      end
    end

    def import
      @imported = 0
      validate_import

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
      return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~/^\.csv$/i

      errors.add :in_file, :invalid_file_type if !SS::Csv.valid_csv?(in_file, headers: true)
      in_file.rewind
    end

    def update_row(row, index)
      edit_range = 'all'
      id = row[header_value_to_text("id")]
      name = row[header_value_to_text("name")].to_s.strip
      start_on = row[header_value_to_text("start_on")].to_s.strip
      end_on = row[header_value_to_text("end_on")].to_s.strip
      color = row[header_value_to_text("color")].to_s.strip
      repeat_type = repeat_type_text_to_value(row[header_value_to_text("repeat_plan_datas.repeat_type")].to_s.strip)
      # return self.errors.add :repeat_type, :inclusion if repeat_type.blank?
      item = create_item_by_repeat_type(repeat_type, id)
      return self.errors.add :base, :not_found, line_no: index, id: id if item.blank?
      if name.blank?
        item.edit_range = edit_range
        item.destroy
        @imported += 1
        return
      end
      item.site = @cur_site
      item.user = @cur_user
      item.edit_range = edit_range
      item.name = name
      item.start_on = start_on
      item.end_on = end_on
      item.color = color
      if repeat_type != "none"
        item.repeat_type = repeat_type
        item.interval = row[header_value_to_text("repeat_plan_datas.interval")].to_s.strip
        item.repeat_start = row[header_value_to_text("repeat_plan_datas.repeat_start")].to_s.strip
        item.repeat_end = row[header_value_to_text("repeat_plan_datas.repeat_end")].to_s.strip
        item.wdays = wdays_text_to_value(row[header_value_to_text("repeat_plan_datas.wdays")].to_s.strip.split(","))
        item.repeat_base = repeat_base_text_to_value(row[header_value_to_text("repeat_plan_datas.repeat_base")].to_s.strip)
      end
      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
    end

    def create_item_by_repeat_type(repeat_type, row_id)
      return self.class.new if row_id.blank?
      if row_id.present?
        item = self.class.unscoped.site(cur_site).where(repeat_plan_id: row_id).first
        return self.class.unscoped.site(cur_site).where(id: row_id).first if item.blank?
      end
      return item.repeat_plan_id = nil if repeat_type == "none"
      item
    end

    def set_errors(item, index)
      errors = item.errors.full_messages.join
      self.errors.add :base, "#{index}: #{errors}"
    end

    def header_value_to_text(value)
      I18n.t("gws/schedule.csv.#{value}")
    end

    def repeat_type_text_to_value(text)
      I18n.t("gws/schedule.options.repeat_type").invert[text].to_s
    end

    def wdays_text_to_value(texts)
      return [] if texts.blank?
      texts.map do |text|
        I18n.t("date.abbr_day_names").find_index text
      end
    end

    def repeat_base_text_to_value(text)
      return "date" if text.blank?
      I18n.t("gws/schedule.options.repeat_base").invert[text].to_s
    end
  end
end
