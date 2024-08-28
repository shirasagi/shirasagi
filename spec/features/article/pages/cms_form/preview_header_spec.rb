require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:part) { create :cms_part_free, html: '<div id="part" class="part"><br><br><br>free html part<br><br><br></div>' }
  let(:layout_html) do
    <<~HTML.freeze
      <html>
      <head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes,minimum-scale=1.0,maximum-scale=2.0">
      </head>
      <body>
        <br><br><br>
        {{ part "#{part.filename.sub(/\..*/, '')}" }}
        <div id="main" class="page">
          {{ yield }}
        </div>
      </body>
      </html>
    HTML
  end
  let!(:layout) { create :cms_layout, html: layout_html }
  let!(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
  let(:text) { unique_id }
  let(:html) { "<p class=\"page-body\">#{text}</p>" }
  let(:text2) { unique_id }
  let(:html2) { "<p class=\"page-body\">#{text2}</p>" }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html, state: "public") }

  before { login_cms_user }

  context "Check Preview Screen with new updates with only text in header." do
    it "check header text" do 
      visit cms_preview_path(site: site, path: item.preview_path)

      expect(page).to have_css("#ss-preview")
      within("#ss-preview") do 
        expect(page).to have_content("画面プレビュー")
      end
    end
  end
end