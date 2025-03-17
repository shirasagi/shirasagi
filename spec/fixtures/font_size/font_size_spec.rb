require 'spec_helper'

describe "fontsize/public_filter", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  shared_examples "fontsize" do
    let!(:layout) { create_cms_layout part }
    let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user, layout_id: layout.id }
    let(:page_html) do
      html = []
      html << '<div id="content">'
      html << '<span class="percent-escaped-url">http%3A%2F%2F127.0.0.1%3A3000</span>'
      html << '<nav class="ss-adobe-reader">'
      html << '  <div>PDFファイルをご覧いただくためには、Adobe Readerのプラグイン（無償）が必要となります。'
      html << '  お持ちでない場合は、お使いの機種とスペックに合わせたプラグインをインストールしてください。</div>'
      html << '  <a href="http://get.adobe.com/jp/reader/">Adobe Readerをダウンロードする</a>'
      html << '</nav>'
      html << '</div>'
      html << '<footer>'
      html << '  〒000-0000　大鷺県シラサギ市小鷺町1丁目1番地1号'
      html << '  <small>Copyright © City of Shirasagi All rights Reserved.</small>'
      html << '</footer>'
      html.join("\n")
    end
    let!(:item) { create :article_page, cur_site: site, cur_node: node, layout: layout, html: page_html }

    before do
      visit item.full_url
      # # フォントサイズのアクセシビリティ機能を初期化
      page.execute_script("SS_Font.render();")
      wait_for_js_ready
    end

    # ヘルパーメソッド: body 要素の inline style の font-size を取得
    def body_font_size
      page.evaluate_script("document.body.style.fontSize")
    end

    it "initial state: standard button pressed" do
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("true")
      end
      expect(body_font_size).to eq("100%")
    end

    it "clicking 'Large' increases font size to 120% and unpresses standard button" do
      within '.accessibility__fontsize' do
        click_on "大きく"
      end
      wait_for_js_ready
      expect(body_font_size).to eq("120%")
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("false")
      end
    end

    it "clicking 'Small' after 'Large' resets font size to 100% and presses standard button" do
      within '.accessibility__fontsize' do
        click_on "大きく"
      end
      wait_for_js_ready
      within '.accessibility__fontsize' do
        click_on "小さく"
      end
      wait_for_js_ready
      expect(body_font_size).to eq("100%")
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("true")
      end
    end

    it "clicking 'Standard' resets font size to 100% and presses standard button" do
      # Change state first by clicking 'Large'
      within '.accessibility__fontsize' do
        click_on "大きく"
      end
      wait_for_js_ready
      within '.accessibility__fontsize' do
        click_on "標準"
      end
      wait_for_js_ready
      expect(body_font_size).to eq("100%")
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("true")
      end
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }
    it_behaves_like "fontsize"
  end

  context "with old accessibility html 1" do
    let!(:part) { create :accessibility_tool_compat1, cur_site: site }
    it_behaves_like "fontsize"
  end

  context "with old accessibility html 2" do
    let!(:part) { create :accessibility_tool_compat2, cur_site: site }
    it_behaves_like "fontsize"
  end

end
