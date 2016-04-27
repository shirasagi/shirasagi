module Sys::SiteCopy::CmsLayout
  extend ActiveSupport::Concern

  private
    @layout_records_map = {}
    #レイアウト:OK
    # NOTE: 20160301 - Cms::Node は "layout_id" を持つため "レイアウト" よりも後に処理を行うべきなので処理の順序を変更
    # 新旧レイアウトレコードIDのKeyVal
    # ex) {<BaseLayoutID>: <DupLayoutID>[, ...]}
    def copy_cms_layout
      Cms::Layout.where(site_id: @site_old.id).each do |cms_layout|
        new_cms_layout = Cms::Layout.new cms_layout.attributes.except(:id, :_id, :site_id, :created, :updated)
        new_cms_layout.site_id = @site.id
        begin
          new_cms_layout.save!
        rescue => exception
          Rails.logger.error(exception.message)
          throw exception
        end
        @layout_records_map[cms_layout.id] = new_cms_layout.id
      end
      return @layout_records_map
    end
end
