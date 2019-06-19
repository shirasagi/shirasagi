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

    begin
      data = NKF.nkf("-wd", src.read)
      src.try(:rewind)
      CSV.parse(data)
    rescue => e
      logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      nil
    end
  end

  def parse_xls
    Timeout.timeout(20) do
      Roo::Spreadsheet.open(file.path, extension: format.downcase.to_sym)
    end
  rescue => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  end

  def parse_xls_page(page = 1)
    page = page.to_i - 1
    page = 0 if page < 0

    Timeout.timeout(20) do
      sp = Roo::Spreadsheet.open(file.path, extension: format.downcase.to_sym)
      [sp.sheets, CSV.parse(sp.sheet(page).to_csv)]
    end
  rescue => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    puts("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    [nil, nil]
  end

  alias csv_present? tsv_present?
  alias parse_csv parse_tsv
end
