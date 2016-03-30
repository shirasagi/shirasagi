module SS::TransSidFilter
  extend ActiveSupport::Concern

  private
    def mobile_path?
      filters = request.env["ss.filters"]
      return false if filters.blank?
      filters.include?(:mobile)
    end
end
