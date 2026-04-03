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
    end

    # ヘルパーメソッド: body 要素の inline style の font-size を取得
    def body_font_size
      page.evaluate_script("document.body.style.fontSize")
    end

    it "initial state: standard button pressed" do
      expect(page).to have_content(I18n.t("ss.font_size.small"))
      expect(page).to have_content(I18n.t("ss.font_size.medium"))
      expect(page).to have_content(I18n.t("ss.font_size.large"))
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.medium")
      end
      expect(body_font_size).to eq("100%")
    end

    it "clicking 'Large' increases font size to 120% and unpresses standard button" do
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.large")
      end
      expect(body_font_size).to eq("120%")
    end

    it "clicking 'Small' after 'Large' resets font size to 100% and presses standard button" do
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.large")
      end
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.small")
      end
      expect(body_font_size).to eq("100%")
    end

    it "clicking 'Standard' resets font size to 100% and presses standard button" do
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.large")
      end
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.medium")
      end
      expect(body_font_size).to eq("100%")
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }
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
    end

    # ヘルパーメソッド: body 要素の inline style の font-size を取得
    def body_font_size
      page.evaluate_script("document.body.style.fontSize")
    end

    it "initial state: standard button pressed" do
      expect(page).to have_content(I18n.t("ss.font_size.small"))
      expect(page).to have_content(I18n.t("ss.font_size.medium"))
      expect(page).to have_content(I18n.t("ss.font_size.large"))
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        standard_btn.click
        expect(standard_btn['aria-pressed']).to eq("true")
      end
      expect(body_font_size).to eq("100%")
    end

    it "clicking 'Large' increases font size to 120% and unpresses standard button" do
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.large")
      end
      expect(body_font_size).to eq("120%")
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("false")
      end
    end

    it "clicking 'Small' after 'Large' resets font size to 100% and presses standard button" do
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.large")
      end
      wait_for_js_ready
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.small")
      end
      wait_for_js_ready
      expect(body_font_size).to eq("100%")
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("true")
      end
    end

    it "clicking 'Standard' resets font size to 100% and presses standard button" do
      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.large")
      end

      within '.accessibility__fontsize' do
        click_on I18n.t("ss.font_size.medium")
      end

      expect(body_font_size).to eq("100%")
      within '.accessibility__fontsize' do
        standard_btn = find('button[data-tool="ss-medium"]')
        expect(standard_btn['aria-pressed']).to eq("true")
      end
    end
  end

  context "special case" do
    let!(:part1) do
      html = <<~HTML
        <div class="accessibility__fontsize">
          <div data-tool="ss-fontsize">
            <div class="on-pc">
              <button type="button" data-tool="ss-small" data-tool-type="button">小さく</button>
              <span class="separator">-</span>
              <button type="button" data-tool="ss-medium" data-tool-type="button">標準</button>
              <span class="separator">-</span>
              <button type="button" data-tool="ss-large" data-tool-type="button">大きく</button>
            </div>
            <div class="on-mobile">
              <button type="button" data-tool="ss-small" data-tool-type="button">
                <span class="material-icons-outlined" aria-label="小さく" role="img">palette</span>
              </button>
              <button type="button" data-tool="ss-medium" data-tool-type="button">
                <span class="material-icons-outlined" aria-label="標準" role="img">palette</span>
              </button>
              <button type="button" data-tool="ss-large" data-tool-type="button">
                <span class="material-icons-outlined" aria-label="大きく" role="img">palette</span>
              </button>
            </div>
          </div>
        </div>
      HTML
      create :cms_part_free, cur_site: site, html: html
    end
    let!(:layout) { create_cms_layout part1 }
    let!(:item) do
      page_html = <<~HTML
        <div id="content">
          hello
        </div>
      HTML
      create :article_page, cur_site: site, layout: layout, html: page_html
    end

    it do
      visit item.full_url
      expect(page).to have_css(".accessibility__fontsize", count: 1)

      within '.on-pc' do
        expect(page).to have_css('[data-tool="ss-small"]', text: I18n.t("ss.font_size.small"))
        expect(page).to have_css('[data-tool="ss-medium"]', text: I18n.t("ss.font_size.medium"))
        expect(page).to have_css('[data-tool="ss-large"]', text: I18n.t("ss.font_size.large"))
      end

      within '.on-mobile' do
        expect(page).to have_css('[data-tool="ss-small"] [aria-label="小さく"]')
        expect(page).to have_css('[data-tool="ss-medium"] [aria-label="標準"]')
        expect(page).to have_css('[data-tool="ss-large"] [aria-label="大きく"]')
      end

      within '.on-pc' do
        click_on I18n.t("ss.font_size.large")
      end
      expect(page).to have_css('body[style="font-size: 120%;"]')
      within '.on-pc' do
        expect(page).to have_css('[data-tool="ss-medium"][aria-pressed="false"]', text: I18n.t("ss.font_size.medium"))
      end
      within '.on-mobile' do
        expect(page).to have_css('[data-tool="ss-medium"][aria-pressed="false"] [aria-label="標準"]')
      end

      within '.on-mobile' do
        first("[aria-label='小さく']").click
      end
      expect(page).to have_css('body[style="font-size: 100%;"]')
      within '.on-pc' do
        expect(page).to have_css('[data-tool="ss-medium"][aria-pressed="true"]', text: I18n.t("ss.font_size.medium"))
      end
      within '.on-mobile' do
        expect(page).to have_css('[data-tool="ss-medium"][aria-pressed="true"] [aria-label="標準"]')
      end
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
end
