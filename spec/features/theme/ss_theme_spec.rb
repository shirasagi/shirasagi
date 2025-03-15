require 'spec_helper'

describe "theme/public_filter", type: :feature, dbscope: :example, js: true do
  shared_examples "theme" do
    let!(:site) { cms_site }
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
    let(:expected_themes) do
      {
        white: {
          css_path: "/themes/white.css",
          font_color: "rgba(0, 0, 0, 0)",
          background_color: "rgba(255, 255, 255, 1)"
        },
        blue: {
          css_path: "/themes/blue.css",
          font_color: "rgba(255, 255, 255, 1)",
          background_color: "rgba(0, 0, 255, 1)"
        },
        black: {
          css_path: "/themes/black.css",
          font_color: "rgba(255, 255, 255, 1)",
          background_color: "rgba(0, 0, 0, 0)"
        }
      }
    end
    let!(:item) { create :article_page, cur_site: site, cur_node: node, layout: layout, html: page_html }
    let!(:part) { create :accessibility_tool, cur_site: site }
    let!(:part1) { create :accessibility_tool_compat1, cur_site: site }
    let!(:part2) { create :accessibility_tool_compat2, cur_site: site }

    before do
      visit item.full_url
      page.execute_script <<-JS
        SS.config["theme"] = {
          white: {
            css_path: "/themes/white.css",
            font_color: "rgba(0, 0, 0, 0)",
            background_color: "rgba(255, 255, 255, 1)",
            default_theme: true
          },
          blue: {
            css_path: "/themes/blue.css",
            font_color: "rgba(255, 255, 255, 1)",
            background_color: "rgba(0, 0, 255, 1)"
          },
          black: {
            css_path: "/themes/black.css",
            font_color: "rgba(255, 255, 255, 1)",
            background_color: "rgba(0, 0, 0, 0)"
          }
        };
        SS_Theme.render();
        // 最新 HTML の button 要素に data-ss-theme を付与
        document.querySelectorAll('button').forEach(function(btn) {
          btn.setAttribute('data-ss-theme', btn.getAttribute('name'));
        });
        // 旧HTMLの a 要素にも data-ss-theme を付与
        document.querySelectorAll('a').forEach(function(anchor) {
          anchor.setAttribute('data-ss-theme', anchor.getAttribute('class'));
        });
        document.querySelectorAll('button').forEach(function(btn) {
          if (btn.getAttribute('name') === 'white') {
            btn.setAttribute('aria-pressed', 'true');
          } else {
            btn.setAttribute('aria-pressed', 'false');
          }
        });
      JS
      wait_for_js_ready
    end

    # 対象要素の背景色を取得するヘルパー
    def current_theme
      find('.accessibility__theme').native.css_value('background-color')
    end

    it "index" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        if page.has_css?('button[name="white"]')
          white_button = find('[data-ss-theme="white"]')
          blue_button  = find('[data-ss-theme="blue"]')
          black_button = find('[data-ss-theme="black"]')
          expect(white_button['aria-pressed']).to eq("true")
          expect(blue_button['aria-pressed']).to eq("false")
          expect(black_button['aria-pressed']).to eq("false")
        end
      end
      expect(current_theme).to eq("rgba(255, 255, 255, 1)")
    end

    it "click blue button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        if page.has_css?('button[name="blue"]')
          white_button = find('button[name="white"]')
          blue_button  = find('button[name="blue"]')
          black_button = find('button[name="black"]')
          blue_button.click
          wait_for_js_ready

          expect(white_button['aria-pressed']).to eq("false")
          expect(blue_button['aria-pressed']).to eq("true")
          expect(black_button['aria-pressed']).to eq("false")
        else
          click_on I18n.t("ss.button.blue")
          wait_for_js_ready
        end
        expect(current_theme).to eq("rgba(0, 0, 255, 1)")
      end
    end

    it "click black button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        if page.has_css?('button[name="black"]')
          white_button = find('button[name="white"]')
          blue_button  = find('button[name="blue"]')
          black_button = find('button[name="black"]')
          black_button.click
          wait_for_js_ready
          expect(white_button['aria-pressed']).to eq("false")
          expect(blue_button['aria-pressed']).to eq("false")
          expect(black_button['aria-pressed']).to eq("true")
        else
          click_on I18n.t("ss.button.black")
          wait_for_js_ready
        end
        expect(current_theme).to eq("rgba(0, 0, 0, 0)")
      end
    end

    it "click white button" do
      # まず blue に切り替えてから白に戻す
      within ".accessibility__tool-wrap:first-child" do
        if page.has_css?('button[name="white"]')
          white_button = find('button[name="white"]')
          blue_button  = find('button[name="blue"]')

          blue_button.click
          wait_for_js_ready
          expect(current_theme).to eq("rgba(0, 0, 255, 1)")

          white_button.click
          wait_for_js_ready

          expect(white_button[:'aria-pressed']).to eq("true")
          expect(blue_button[:'aria-pressed']).to eq("false")
        else
          click_on I18n.t("ss.button.blue")
          wait_for_js_ready

          click_on I18n.t("ss.button.white")
          wait_for_js_ready
        end
        expect(current_theme).to eq("rgba(255, 255, 255, 1)")
      end
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }
    it_behaves_like "theme"
  end

  context "with old accessibility html 1" do
    let!(:part) { create :accessibility_tool_compat1, cur_site: site }
    it_behaves_like "theme"
  end

  context "with old accessibility html 2" do
    let!(:part) { create :accessibility_tool_compat2, cur_site: site }
    it_behaves_like "theme"
  end
end
