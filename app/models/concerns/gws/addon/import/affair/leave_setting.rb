require "csv"

module Gws::Addon::Import::Affair
  module LeaveSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported
      permit_params :in_file
    end

    module ClassMethods
      def csv_headers
        %w(id name staff_address_uid count)
      end

      def enum_csv
        criteria = self.all
        Enumerator.new do |y|
          y << encode_sjis(csv_headers.map { |k| I18n.t("gws/affair.export.leave_setting.#{k}") }.to_csv)
          criteria.each do |item|
            line = []
            line << item.id
            line << item.target_user.try(:name)
            line << item.target_user.try(:staff_address_uid)
            line << item.count
            y << encode_sjis(line.to_csv)
          end
        end
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
      return errors.add :cur_site, :blank if cur_site.blank?
      return errors.add :cur_user, :blank if cur_user.blank?
      return errors.add :year, :blank if year.blank?

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
      id = row[I18n.t("gws/affair.export.leave_setting.id")].to_s.strip
      name = row[I18n.t("gws/affair.export.leave_setting.name")].to_s.strip
      staff_address_uid = row[I18n.t("gws/affair.export.leave_setting.staff_address_uid")].to_s.strip
      count = row[I18n.t("gws/affair.export.leave_setting.count")].to_s.strip

      if staff_address_uid.blank? || count.blank?
        return
      end

      if id.present?
        item = self.class.site(cur_site).where(id: id).first
        if item.nil?
          self.errors.add :base, "#{index}: 休暇設定が見つかりません。（#{id}）"
          return false
        end
      end

      target_user = Gws::User.active.where(staff_address_uid: staff_address_uid).first
      if target_user.nil?
        self.errors.add :base, "#{index}: 対象ユーザーが見つかりません。（#{[name, staff_address_uid].select(&:present?).join(", ")}）"
        return false
      end

      item ||= self.class.new
      item.site = cur_site
      item.user = cur_user
      item.year = year
      item.target_user = target_user
      item.count = count.to_i
      item.user_ids = [cur_user.id]

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
    end

    def set_errors(item, index)
      return if item.errors.empty?
      self.errors.add :base, "#{index}: #{item.errors.full_messages.join(", ")}"
    end
  end
end