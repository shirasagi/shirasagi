module Opendata::TsvParseable
  extend ActiveSupport::Concern

  def tsv_present?
    if try(:tsv) || %(CSV TSV).index(try(:format).try(:upcase))
      true
    end
  end

  def parse_tsv
    require "nkf"
    require "csv"

    src  = try(:tsv) || try(:file)
    data = NKF.nkf("-w", src.read)
    sep  = data =~ /\t/ ? "\t" : ","
    CSV.parse(data, col_sep: sep) rescue nil
  end

  alias_method :csv_present?, :tsv_present?
  alias_method :parse_csv, :parse_tsv
end
