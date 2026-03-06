class Cms::CheckLinks::Errors
  include ActiveModel::Model

  attr_accessor :errors, :display_meta

  delegate :present?, :blank?, :any?, :empty?, to: :errors

  def error_count
    error_referrers.size
  end

  def to_message
    msg = ["[#{error_count} errors]"]
    error_referrers.map do |source|
      msg << source.full_url.to_s

      error_links = source.links.select { _1.status == :error }
      msg << error_links.map do |link|
        meta = display_meta ? " #{link.meta}" : ""
        "  - #{link.full_url}#{meta}"
      end
    end
    msg.join("\n")
  end

  def to_csv
    csv = CSV.generate do |data|
      data << %w(reference url)
      error_referrers.each do |source|
        error_links = source.links.select { _1.status == :error }
        error_links.each do |link|
          data << [source.full_url.request_uri, link.href]
        end
      end
    end
    SS::Csv::UTF8_BOM + csv
  end

  private

  def error_referrers
    @error_referrers ||= begin
      error_referrers = errors.map(&:referrers)
      error_referrers.flatten!
      error_referrers.uniq!
      error_referrers.sort_by!(&:sequence)
      error_referrers
    end
  end
end
