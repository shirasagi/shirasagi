require "csv"

module Gws::Addon::Import::Affair
  module Capital
    module Member
      extend ActiveSupport::Concern
      extend SS::Addon

      module ClassMethods
        def member_csv_headers
          %w(
            name
            staff_address_uid
            project_code
            detail_code
          )
        end

        def member_enum_csv(site)
          criteria = self.all
          Enumerator.new do |y|
            y << encode_sjis(member_csv_headers.map { |k| I18n.t("gws/affair.export.capital_member.#{k}") }.to_csv)
            Gws::User.site(site).active.order_by_title(site).each do |member|
              item = criteria.in(member_ids: member.id).first
              line = []
              line << member.name
              line << member.staff_address_uid
              line << item.try(:project_code)
              line << item.try(:detail_code)
              y << encode_sjis(line.to_csv)
            end
          end
        end

        def encode_sjis(str)
          str.encode("SJIS", invalid: :replace, undef: :replace)
        end
      end

      def import_member
        @imported = 0
        validate_import
        return false unless errors.empty?

        I18n.with_locale(I18n.default_locale) do
          SS::Csv.foreach_row(in_file, headers: true) do |row, i|
            update_member_row(row, i + 2)
          end
        end
        errors.empty?
      end

      def update_member_row(row, index)
        staff_address_uid = row[I18n.t("gws/affair.export.capital_member.staff_address_uid")].to_s.strip
        project_code = row[I18n.t("gws/affair.export.capital_member.project_code")].to_s.strip
        detail_code = row[I18n.t("gws/affair.export.capital_member.detail_code")].to_s.strip

        if staff_address_uid.blank? || project_code.blank? || detail_code.blank?
          return
        end

        user = Gws::User.site(cur_site).active.where(staff_address_uid: staff_address_uid).first
        if user.nil?
          self.errors.add :base, "#{index}:ユーザーが見つかりません。(宛名番号 #{staff_address_uid})"
          return
        end

        if project_code.present? || detail_code.present?
          item = self.class.unscoped.site(cur_site).where(
            year_id: year.id,
            project_code: project_code,
            detail_code: detail_code
          ).first

          if item.nil?
            self.errors.add :base, "#{index}:原資区分が見つかりません。(明細 #{detail_code}, 事業コード #{project_code})"
            return
          end
        else
          item = nil
        end

        result = true
        if item
          # set user in target capital
          item.member_ids = (item.member_ids + [user.id]).uniq
          result = item.save
        end

        if result
          # unset user in other capitals
          self.class.site(cur_site).where(year_id: year.id).in(member_ids: user.id).each do |capital|
            next if item && (capital.id == item.id)
            capital.member_ids = (capital.member_ids - [user.id]).uniq
            capital.save
          end

          @imported += 1
        else
          set_errors(item, index)
        end
        item
      end
    end
  end
end
