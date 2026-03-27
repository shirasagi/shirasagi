class Cms::AllContentsMoveValidator
  include ActiveModel::Model
  include Cms::CsvImportBase

  # CSVに必須のヘッダー列
  # Cms::CsvImportBase の valid_csv? が SS::Csv.valid_csv? に required_headers を渡し、
  # ヘッダー行に必須列が含まれているかを検証する（既存のシラサギ標準パターン）
  self.required_headers = -> { [
    I18n.t('cms.all_contents_moves.csv_headers.page_id'),
    I18n.t('cms.all_contents_moves.csv_headers.filename')
  ] }
end
