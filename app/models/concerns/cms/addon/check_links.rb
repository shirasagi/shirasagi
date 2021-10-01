module Cms::Addon
  module CheckLinks
    extend ActiveSupport::Concern
    extend SS::Addon

    def latest_check_links_report
      @_latest_check_links_report ||= Cms::CheckLinks::Report.site(site).first
    end

    def check_links_error
      return if latest_check_links_report.nil?
      return if @_check_links_error == false

      if self.class.include?(Cms::Model::Page)
        @_check_links_error = Cms::CheckLinks::Error::Page.where(report_id: latest_check_links_report.id, page_id: id).first
      elsif self.class.include?(Cms::Model::Node)
        @_check_links_error = Cms::CheckLinks::Error::Node.where(report_id: latest_check_links_report.id, node_id: id).first
      else
        @_check_links_error = false
        nil
      end
    end
  end
end
