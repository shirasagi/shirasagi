require 'spec_helper'

describe "member_blogs", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:layout) { create(:cms_layout, site: site) }
  let!(:blogs_node) { create :member_node_blog, cur_site: site, layout: layout }
  let!(:node) { create :member_node_blog_page, cur_site: site, cur_node: blogs_node, layout: layout }
  let(:html) do
    html = []
    html << "<p>"
    html << '  <link rel="stylesheet" href="http://www.example.jp/dangerous.css">'
    html << '  <a href="http://www.example.jp/">危険なサイト1</a>'
    html << '  <a href="https://www.example.jp/">危険なサイト2</a>'
    html << '  <a href="mailto:aaa@example.jp">危険なサイト3</a>'
    html << '  <a href="javascript:alert(\'危険な操作\');">危険なサイト4</a>'
    html << '  <script>alert("危険な操作");</script>'
    html << "</p>"
    html.join("\n")
  end
  let!(:item) { create(:member_blog_page, cur_site: site, cur_node: node, html: html) }

  context "basic crud" do
    it "#index" do
      visit item.full_url

      # http or https links are safe
      expect(page).to have_css(".body a[href='http://www.example.jp/']", text: "危険なサイト1")
      expect(page).to have_css(".body a[href='https://www.example.jp/']", text: "危険なサイト2")
      # no mailto links
      expect(page).to have_css(".body", text: "危険なサイト3")
      expect(page).to have_no_css(".body a[href='mailto:aaa@example.jp']")
      # no javascript links
      expect(page).to have_css(".body", text: "危険なサイト4")
      expect(page).to have_no_css(".body a[href=\"javascript:alert('危険な操作');\"]")
      # no script tags
      expect(page).to have_css(".body", text: 'alert("危険な操作");')
      expect(page).to have_no_css(".body script")
    end
  end
end
