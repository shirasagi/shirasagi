#frozen_string_literal: true

class Article::Page::ExportJob < Cms::ApplicationJob
  include SS::CsvExportBase

  private

  def csv_encoding
    csv_encoding = task.params["encoding"].presence if task.params.present?
    csv_encoding || "UTF-8"
  end

  def create_exporter
    form_id = task.params["form_id"].presence if task.params.present?
    if form_id.present? && node.respond_to?(:st_forms)
      form = node.st_forms.where(id: form_id).first
    end

    truncate = task.params["truncate"].presence if task.params.present?
    truncate ||= "no"
    truncate = truncate != "no" if truncate

    criteria = Article::Page.all
    criteria = criteria.site(site)
    criteria = criteria.node(node) if node
    criteria = criteria.allow(:read, user, site: site, node: node)
    # 効率を優先し id の降順に並べる
    criteria = criteria.reorder(id: -1)

    if form.present?
      criteria = criteria.where(form_id: form)
    else
      criteria = criteria.exists(form_id: false)
    end

    Cms::PageExporter.new(mode: "article", site: site, truncate: truncate, criteria: criteria)
  end

  def canonical_scheme
    site.mypage_scheme.presence || (site.https == "enabled" ? "https" : "http")
  end

  def canonical_domain
    site.mypage_domain.presence || site.domain
  end
end
