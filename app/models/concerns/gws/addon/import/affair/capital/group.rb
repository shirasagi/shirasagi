require "csv"

module Gws::Addon::Import::Affair
  module Capital
    module Group
      extend ActiveSupport::Concern
      extend SS::Addon

      module ClassMethods
        def group_csv_headers
          %w(
            group_name
            group_code
            project_code
            detail_code
          )
        end

        def group_enum_csv(site)
          criteria = self.all
          Enumerator.new do |y|
            y << encode_sjis(group_csv_headers.map { |k| I18n.t("gws/affair.export.capital_group.#{k}") }.to_csv)
            Gws::Group.site(site).active.order_by(_id: 1).each do |group|
              item = criteria.in(member_group_ids: group.id).first
              line = []
              line << group.name
              line << group.group_code
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

      def import_group
        @imported = 0
        validate_import
        return false unless errors.empty?

        I18n.with_locale(I18n.default_locale) do
          table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
          table.each_with_index do |row, i|
            update_group_row(row, i + 2)
          end
        end
        errors.empty?
      end

      def update_group_row(row, index)
        group_code = row[I18n.t("gws/affair.export.capital_group.group_code")].to_s.strip
        project_code = row[I18n.t("gws/affair.export.capital_group.project_code")].to_s.strip
        detail_code = row[I18n.t("gws/affair.export.capital_group.detail_code")].to_s.strip

        if group_code.blank? || project_code.blank? || detail_code.blank?
          return
        end

        group = Gws::Group.active.site(cur_site).where(group_code: group_code).first
        if group.nil?
          self.errors.add :base, "#{index}:グループが見つかりません。(所属コード #{group_code})"
          return
        end

        if project_code.present? || detail_code.present?
          item = self.class.site(cur_site).where(
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
          # set group in target capital
          item.member_group_ids = (item.member_group_ids + [group.id]).uniq
          result = item.save
        end

        if result
          # unset group in other capitals
          self.class.site(cur_site).where(year_id: year.id).in(member_group_ids: group.id).each do |capital|
            next if item && (capital.id == item.id)
            capital.member_group_ids = (capital.member_group_ids - [group.id]).uniq
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
