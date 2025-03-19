require 'spec_helper'

describe "theme/public_filter", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  shared_examples "theme" do
    let!(:layout) { create_cms_layout part }
    let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user, layout_id: layout.id }
    let(:page_html) do
      <<~HTML
        <html>
          <head>
            {{ ss_scripts }}
          </head>
          <body>
            <div id="content">
              <span class="percent-escaped-url">http%3A%2F%2F127.0.0.1%3A3000</span>
              <nav class="ss-adobe-reader">
                <div>
                  PDFファイルをご覧いただくためには、Adobe Readerのプラグイン（無償）が必要となります。
                  お持ちでない場合は、お使いの機種とスペックに合わせたプラグインをインストールしてください。
                </div>
                <a href="http://get.adobe.com/jp/reader/">Adobe Readerをダウンロードする</a>
              </nav>
            </div>
            <footer>
              〒000-0000　大鷺県シラサギ市小鷺町1丁目1番地1号
              <small>Copyright © City of Shirasagi All rights Reserved.</small>
            </footer>
          </body>
        </html>
      HTML
    end

    let(:expected_themes) do
      {
        white: {
          css_path: "/themes/white.css",
          font_color: "rgba(0, 0, 0, 1)",
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
          background_color: "rgba(0, 0, 0, 1)"
        }
      }
    end
    let!(:item) { create :article_page, cur_site: site, cur_node: node, layout: layout, html: page_html }

    before do
      visit item.full_url
      page.execute_script <<-JS
        SS.config["theme"] = {
          white: {
            css_path: "/themes/white.css",
            font_color: "rgba(0, 0, 0, 1)",
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
            background_color: "rgba(0, 0, 0, 1)"
          }
        };
        SS_Theme.render();
      JS
    end

    # 対象要素の背景色を取得するヘルパー
    def current_theme
      find('.accessibility__theme').native.css_value('background-color')
    end

    it "index" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        expect(page).to have_content(I18n.t("ss.button.white"))
        expect(page).to have_content(I18n.t("ss.button.blue"))
        expect(page).to have_content(I18n.t("ss.button.black"))
      end
    end

    it "click blue button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.blue")
        expect(current_theme).to eq("rgba(0, 0, 255, 1)")
      end
    end

    it "click black button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.black")
        expect(current_theme).to eq("rgba(0, 0, 0, 1)")
      end
    end

    it "click white button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.black")
        expect(current_theme).to eq("rgba(0, 0, 0, 1)")
      end
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.white")
        expect(current_theme).to eq("rgba(255, 255, 255, 1)")
      end
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }
    let!(:layout) { create_cms_layout part }
    let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user, layout_id: layout.id }
    let(:page_html) do
      <<~HTML
        <html>
          <head>
            {{ ss_scripts }}
          </head>
          <body>
            <div id="content">
              <span class="percent-escaped-url">http%3A%2F%2F127.0.0.1%3A3000</span>
              <nav class="ss-adobe-reader">
                <div>
                  PDFファイルをご覧いただくためには、Adobe Readerのプラグイン（無償）が必要となります。
                  お持ちでない場合は、お使いの機種とスペックに合わせたプラグインをインストールしてください。
                </div>
                <a href="http://get.adobe.com/jp/reader/">Adobe Readerをダウンロードする</a>
              </nav>
            </div>
            <footer>
              〒000-0000　大鷺県シラサギ市小鷺町1丁目1番地1号
              <small>Copyright © City of Shirasagi All rights Reserved.</small>
            </footer>
          </body>
        </html>
      HTML
    end

    let(:expected_themes) do
      {
        white: {
          css_path: "/themes/white.css",
          font_color: "rgba(0, 0, 0, 1)",
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
          background_color: "rgba(0, 0, 0, 1)"
        }
      }
    end
    let!(:item) { create :article_page, cur_site: site, cur_node: node, layout: layout, html: page_html }

    before do
      visit item.full_url
      page.execute_script <<-JS
        SS.config["theme"] = {
          white: {
            css_path: "/themes/white.css",
            font_color: "rgba(0, 0, 0, 1)",
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
            background_color: "rgba(0, 0, 0, 1)"
          }
        };
        SS_Theme.render();
      JS
    end

    # 対象要素の背景色を取得するヘルパー
    def current_theme
      find('.accessibility__theme').native.css_value('background-color')
    end

    it "index" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        expect(page).to have_content(I18n.t("ss.button.white"))
        expect(page).to have_content(I18n.t("ss.button.blue"))
        expect(page).to have_content(I18n.t("ss.button.black"))
      end
    end

    it "click blue button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.blue")
        white_button = find('button#ss-theme-0-white')
        blue_button  = find('button#ss-theme-0-blue')
        black_button = find('button#ss-theme-0-black')
        expect(white_button['aria-pressed']).to eq("false")
        expect(blue_button['aria-pressed']).to eq("true")
        expect(black_button['aria-pressed']).to eq("false")
        expect(current_theme).to eq("rgba(0, 0, 255, 1)")
      end
    end

    it "click black button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.black")
        white_button = find('button#ss-theme-0-white')
        blue_button  = find('button#ss-theme-0-blue')
        black_button = find('button#ss-theme-0-black')
        expect(white_button['aria-pressed']).to eq("false")
        expect(blue_button['aria-pressed']).to eq("false")
        expect(black_button['aria-pressed']).to eq("true")
        expect(current_theme).to eq("rgba(0, 0, 0, 1)")
      end
    end

    it "click white button" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.black")
        white_button = find('button#ss-theme-0-white')
        blue_button  = find('button#ss-theme-0-blue')
        black_button = find('button#ss-theme-0-black')
        expect(white_button['aria-pressed']).to eq("false")
        expect(blue_button['aria-pressed']).to eq("false")
        expect(black_button['aria-pressed']).to eq("true")
        expect(current_theme).to eq("rgba(0, 0, 0, 1)")
      end
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("ss.bg_color"))
        click_on I18n.t("ss.button.white")
        white_button = find('button#ss-theme-0-white')
        blue_button  = find('button#ss-theme-0-blue')
        black_button = find('button#ss-theme-0-black')
        expect(white_button['aria-pressed']).to eq("true")
        expect(blue_button['aria-pressed']).to eq("false")
        expect(black_button['aria-pressed']).to eq("false")
        expect(current_theme).to eq("rgba(255, 255, 255, 1)")
      end
    end
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
