module SS::CsvHeader
  extend ActiveSupport::Concern

  included do
    field :csv_headers, type: Array, default: []
  end

  def csv_or_xlsx?
    %w(CSV XLS XLSX).include?(extname.upcase)
  end

  private

  def extract_csv_headers(file)
    extractor = SS::CsvExtractor.new(file)
    extractor.extract_csv_headers
    self.csv_headers = extractor.csv_headers
  end
end
