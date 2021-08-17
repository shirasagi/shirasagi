class Cms::CheckLinks::Error::Base
  include SS::Document
  include SS::Reference::Site
  include Cms::GroupPermission

  set_permission_name "cms_check_links_errors"

  belongs_to :report, class_name: "Cms::CheckLinks::Report"

  field :ref, type: String
  field :ref_url, type: String

  field :name, type: String
  field :filename, type: String
  field :urls, type: Array, default: []

  validates :ref, presence: true
  validates :ref_url, presence: true

  validates :name, presence: true
  validates :report_id, presence: true

  def content
  end

  def private_show_path(*args)
  end

  def preview_path
    ref.sub(/^\//, "")
  end

  def group_label
    names = groups.pluck(:name).sort_by { |name| name.count("/") * -1 }
    label = names.first
    label += " ..." if names.size >= 2
    label
  end

  class << self
    def content_name
    end

    def and_report(report)
      where(report_id: report.id)
    end

    def search(params = {})
      criteria = all
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in(params[:keyword], :name, :ref)
      end

      criteria
    end

    def enum_csv
      criteria = self.all
      max_urls = criteria.pluck(:urls).map(&:size).max
      Enumerator.new do |y|
        headers = %w(name filename ref_url group_ids).map { |k| self.t(k) }
        headers += (1..max_urls).map { |i| "#{I18n.t("ss.broken_link")}#{i}" }
        y << (headers.to_csv).encode("SJIS", invalid: :replace, undef: :replace)
        criteria.each do |item|
          line = []
          line << item.name
          line << item.filename
          line << item.ref_url
          line << item.groups.pluck(:name).join("\n")
          item.urls.each do |url|
            line << url
          end
          y << (line.to_csv).encode("SJIS", invalid: :replace, undef: :replace)
        end
      end
    end
  end
end
