module Opendata::PdfParseable
  extend ActiveSupport::Concern

  def extract_pdf_base64_images(limit = nil)
    limit ||= SS.config.opendata.preview["pdf"]["page_limit"]

    return [] unless file && pdf_present?

    parse_command = SS.config.opendata.preview["pdf"]["parse_command"]
    parse_command += " \"#{file.path}\" \"#{limit}\""

    output, error, status = Open3.capture3(parse_command)
    raise Timeout::Error.new if status.exitstatus == 124

    if output.present?
      output.split("\n").map do |base64|
        next nil if base64.blank?
        ret = Base64.strict_decode64(base64) rescue nil
        ret ? base64 : nil
      end.compact
    else
      []
    end
  end
end
