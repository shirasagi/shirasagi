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
        new_cms_layout = Cms::Layout.new
        new_cms_layout = cms_layout.dup
        new_cms_layout.site_id = @site.id
        if new_cms_layout.save
          @layout_records_map[cms_layout.id] = new_cms_layout.id
        end
      end
      return @layout_records_map
    end
end