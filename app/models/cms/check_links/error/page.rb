class Cms::CheckLinks::Error::Page < Cms::CheckLinks::Error::Base
  belongs_to :page, class_name: "Cms::Page"

  set_permission_name "cms_check_links_errors"

  def content
    page
  end

  def private_show_path(*args)
    options = args.extract_options!
    options.merge!(site: (cur_site || site), report_id: report.id, id: id)
    helper_mod = Rails.application.routes.url_helpers
    helper_mod.cms_check_links_report_page_path(*args, options) rescue nil
  end

  class << self
    def content_name
      I18n.t("ss.page")
    end
  end
end
