require 'spec_helper'

describe "cms_preview", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  context "with upload js file" do
    let!(:node) { create_once :uploader_node_file, filename: "js" }
    let!(:uploader_path) { uploader_files_path site.id, node }
    let!(:file) { Rails.root.join("spec", "fixtures", "ss", "sample.js").to_s }

    let!(:layout) { create :cms_layout, html: layout_html }
    let!(:layout_html) do
      h = []
      h << '<html>'
      h << '<head><script src="/js/sample.js"></script></head>'
      h << '<body><div id="sample"></div><body>'
      h << '</html>'
      h .join
    end
    let!(:item) { create(:cms_page, cur_site: site, html: html, layout: layout, filename: "index.html") }
    let!(:pc_preview_path) { cms_preview_path(site: site, path: item.url[1..-1]) }

    before { login_cms_user }

    context "pc preview" do
      it do
        visit uploader_path
        click_link I18n.t('ss.links.upload')

        within "form" do
          attach_file "item[files][]", file
          click_button I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit pc_preview_path
        expect(page).to have_text("appended by sample.js")
      end
    end
  end
end
