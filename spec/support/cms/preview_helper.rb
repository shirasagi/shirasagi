module CmsPreviewHelper
  def create_preview_layout_with_title(site, name = "プレビュー用レイアウト")
    create(:cms_layout_with_title, cur_site: site, name: name)
  end

  def setup_preview_with_title_layout
    @preview_layout = create_preview_layout_with_title(cms_site)
  end
end

RSpec.configure do |config|
  config.include CmsPreviewHelper, type: :feature
end
