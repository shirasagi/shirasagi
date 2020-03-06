module Opendata::TsvParseable
  extend ActiveSupport::Concern

  def tsv_present?
    if try(:tsv) || %w(CSV TSV).index(try(:format).try(:upcase))
      true
    end
  end

  def xls_present?
    %w(XLS XLSX).index(format.to_s.upcase) != nil
  end

  def parse_tsv(src = nil)
    require "nkf"
    require "csv"

    src ||= try(:tsv) || try(:file)

    data = NKF.nkf('-wd', src.read)
    src.try(:rewind)
    CSV.parse(data)
  rescue CSV::MalformedCSVError => e
    logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  rescue => e
    logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def parse_xls(page = 1)
    page = page.to_i - 1
    page = 0 if page < 0

    sp = Roo::Spreadsheet.open(file.path, extension: format.downcase.to_sym)
    [sp.sheets, CSV.parse(sp.sheet(page).to_csv)]
  rescue => e
    logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    [nil, nil]
  end

  alias csv_present? tsv_present?
  alias parse_csv parse_tsv
end
