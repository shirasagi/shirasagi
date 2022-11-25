require "csv"

module Gws::Addon::Import::Affair
  module Capital
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :imported
      permit_params :in_file

      #field :budget_code, type: Integer             # 予算区分
      #field :budget_number, type: Integer           # 予算号数
      #field :affiliation_code, type: Integer        # 所属係コード
      #field :affiliation_name, type: String         # 所属名称
      #field :account_code, type: Integer            # 会計コード
      #field :transfer_code, type: Integer           # 繰越区分
      #field :fifth_assessment_amount, type: Integer # 五次査定額
      #field :statistics_name1, type: String         # 統計性質名称１
      #field :statistics_name2, type: String         # 統計性質名称２
    end

    module ClassMethods
      def csv_headers
        %w(
          article_code
          section_code
          subsection_code
          item_code
          subitem_code
          project_code
          detail_code
          project_name
          description_name
          item_name
          subitem_name
        )
      end

      def enum_csv
        criteria = self.all
        Enumerator.new do |y|
          y << encode_sjis(csv_headers.map { |k| I18n.t("gws/affair.export.capital.#{k}") }.to_csv)
          criteria.each do |item|
            line = []
            line << item.article_code
            line << item.section_code
            line << item.subsection_code
            line << item.item_code
            line << item.subitem_code
            line << item.project_code
            line << item.detail_code
            line << item.project_name
            line << item.description_name
            line << item.item_name
            line << item.subitem_name
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

      I18n.with_locale(I18n.default_locale) do
        table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
        table.each_with_index do |row, i|
          update_row(row, i + 2)
        end
      end
      errors.empty?
    end

    private

    def validate_import
      return errors.add :in_file, :blank if in_file.blank?
      return errors.add :year, :blank if year.blank?
      return errors.add :cur_site, :blank if cur_site.blank?

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
      article_code    = row[I18n.t("gws/affair.export.capital.article_code")].to_s.strip
      section_code    = row[I18n.t("gws/affair.export.capital.section_code")].to_s.strip
      subsection_code = row[I18n.t("gws/affair.export.capital.subsection_code")].to_s.strip
      item_code       = row[I18n.t("gws/affair.export.capital.item_code")].to_s.strip
      subitem_code    = row[I18n.t("gws/affair.export.capital.subitem_code")].to_s.strip
      project_code    = row[I18n.t("gws/affair.export.capital.project_code")].to_s.strip
      detail_code     = row[I18n.t("gws/affair.export.capital.detail_code")].to_s.strip

      project_name     = row[I18n.t("gws/affair.export.capital.project_name")].to_s.strip
      description_name = row[I18n.t("gws/affair.export.capital.description_name")].to_s.strip
      item_name        = row[I18n.t("gws/affair.export.capital.item_name")].to_s.strip
      subitem_name     = row[I18n.t("gws/affair.export.capital.subitem_name")].to_s.strip

      item = self.class.unscoped.site(cur_site).where(
        year_id: year.id,
        article_code: article_code,
        section_code: section_code,
        subsection_code: subsection_code,
        item_code: item_code,
        subitem_code: subitem_code,
        project_code: project_code,
        detail_code: detail_code
      ).first
      item ||= self.class.new

      item.site             = @cur_site
      item.user             = @cur_user

      item.article_code     = article_code
      item.section_code     = section_code
      item.subsection_code  = subsection_code
      item.item_code        = item_code
      item.subitem_code     = subitem_code
      item.project_code     = project_code
      item.detail_code      = detail_code
      item.project_name     = project_name
      item.description_name = description_name
      item.item_name        = item_name
      item.subitem_name     = subitem_name

      item.year              = year
      item.year_name         = year.try(:name)
      item.year_code         = year.try(:code)

      if item.save
        @imported += 1
      else
        set_errors(item, index)
      end
      item
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
