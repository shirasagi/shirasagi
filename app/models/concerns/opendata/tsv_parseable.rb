module Opendata::TsvParseable
  extend ActiveSupport::Concern

  def tsv_present?
    if try(:tsv) || %(CSV TSV).index(try(:format).try(:upcase))
      true
    end
  end

  def parse_tsv(src = nil)
    require "nkf"
    require "csv"

    src ||= try(:tsv) || try(:file)

    begin
      data = NKF.nkf("-w", src.read)
      src.try(:rewind)
      sep  = data =~ /\t/ ? "\t" : ","
      CSV.parse(data, col_sep: sep)
    rescue => e
      logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      nil
    end
  end

  alias_method :csv_present?, :tsv_present?
  alias_method :parse_csv, :parse_tsv
end
