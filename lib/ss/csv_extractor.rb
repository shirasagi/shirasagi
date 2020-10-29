class SS::CsvExtractor
  attr_accessor :file, :filename, :extname, :csv_headers

  def initialize(file)
    @file = file
    @filename = file.respond_to?(:original_filename) ? file.original_filename : file.filename
    @extname = ::File.extname(@filename).delete(".")
    @csv_headers = []
  end

  public

  def extract_csv_headers
    if extname.upcase == "XLS" || extname.upcase == "XLSX"
      extract_headers_from_xlsx
    elsif extname.upcase == "CSV"
      extract_headers_from_csv
    end
  rescue CSV::MalformedCSVError => e
    logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  private

  def extract_headers_from_xlsx
    ext = extname.downcase.to_sym
    return unless Roo::CLASS_FOR_EXTENSION.include?(ext)

    Timeout.timeout(60) do
      sp = Roo::Spreadsheet.open(file.path, extension: ext)
      csv = sp.sheet(0).to_csv
      @csv_headers = CSV::parse(csv).first.select { |v| v.present? }
    end
  end

  def extract_headers_from_csv
    require "nkf"

    data = NKF.nkf('-wd', file.read)
    csv = CSV.parse(data, headers: true)
    @csv_headers = csv.headers.select { |v| v.present? }
  end
end
