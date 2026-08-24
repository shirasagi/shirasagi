#frozen_string_literal: true

class Cms::AllContentsExportJob < Cms::ApplicationJob
  include SS::CsvExportBase

  private

  def csv_encoding
    csv_encoding = task.params.fetch("encoding", "UTF-8") if task.params.present?
    csv_encoding || "UTF-8"
  end

  def create_exporter
    truncate = task.params.fetch("truncate", "yes") if task.params.present?
    truncate = truncate != "no" if truncate

    Cms::AllContent.new(site: site, truncate: truncate)
  end

  def canonical_scheme
    site.mypage_scheme.presence || (site.https == "enabled" ? "https" : "http")
  end

  def canonical_domain
    site.mypage_domain.presence || site.domain
  end
end
