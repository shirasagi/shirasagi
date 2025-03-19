require 'spec_helper'

describe "voice/public_filter", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  shared_examples "voice" do
    let!(:layout) { create_cms_layout part }
    let!(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
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
    let!(:item) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id, name: '&times;×', html: page_html }

    before do
      visit item.full_url
    end

    it "renders a button with proper aria attributes" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("voice.ss_voice"))
        if page.has_css?('button[aria-haspopup="dialog"]')
          button = find('button[aria-haspopup="dialog"]')
          expect(button['aria-expanded']).to eq('false')
        else
          next
        end
        voice_controller = find('#ss-voice-controller-0')
        expect(voice_controller[:style]).to include("display: none")
      end
    end

    it "updates aria-expanded to true when opened" do
      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("voice.ss_voice"))
        click_on I18n.t("voice.ss_voice")
        if page.has_css?('button[aria-haspopup="dialog"]')
          button = find('button[aria-haspopup="dialog"]')
          expect(button['aria-expanded']).to eq('true')
        else
          next
        end
        voice_controller = find('#ss-voice-controller-0')
        expect(voice_controller[:style]).to include("")
      end
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }

    it_behaves_like "voice"
  end

  context "with old accessibility html 1" do
    let!(:part) { create :accessibility_tool_compat1, cur_site: site }

    it_behaves_like "voice"
  end

  context "with old accessibility html 2" do
    let!(:part) { create :accessibility_tool_compat2, cur_site: site }

    it_behaves_like "voice"
  end

  context "with multiple accessibility parts" do
    let!(:part1) { create :accessibility_tool, cur_site: site }
    let!(:part2) { create :accessibility_tool_compat1, cur_site: site }
    let!(:part3) { create :accessibility_tool_compat2, cur_site: site }
    let!(:layout) { create_cms_layout part1, part2, part3 }
    let!(:node) { create :article_node_page, cur_site: site, layout: layout }
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

    it do
      visit item.full_url

      expect(page).to have_css(".accessibility__tool-wrap", count: 3)

      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("voice.ss_voice"))
        if page.has_css?('button[aria-haspopup="dialog"]')
          button = find('button[aria-haspopup="dialog"]')
          expect(button['aria-expanded']).to eq('false')
        else
          next
        end
        voice_controller = find('#ss-voice-controller-0')
        expect(voice_controller[:style]).to include("display: none")
      end

      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("voice.ss_voice"))
        click_on I18n.t("voice.ss_voice")
        if page.has_css?('button[aria-haspopup="dialog"]')
          button = find('button[aria-haspopup="dialog"]')
          expect(button['aria-expanded']).to eq('true')
        else
          next
        end
        voice_controller = find('#ss-voice-controller-0')
        expect(voice_controller[:style]).to include("")
      end
    end
  end

  context "with old accessibility custom html" do
    let!(:part) { create :accessibility_tool_custom, cur_site: site }
    let!(:layout) { create_cms_layout part }
    let!(:node) { create :article_node_page, cur_site: site, layout: layout }
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

    it do
      visit item.full_url
      within ".accessibility__tool-wrap:first-child" do
        first(".accessibility__voice").text.split(/\s+/).tap do |text_segments|
          expect(text_segments).to include(I18n.t("voice.ss_voice"), "voice_button")
          expect(text_segments.count(I18n.t("voice.ss_voice"))).to eq 1
          expect(text_segments.count("voice_button")).to eq 1
        end
      end

      within ".accessibility__tool-wrap:first-child" do
        expect(page).to have_content(I18n.t("voice.ss_voice"))
        voice_controller = find('#ss-voice-controller-0')
        expect(voice_controller[:style]).to include("display: none")
      end

      within ".accessibility__tool-wrap:first-child" do
        click_on I18n.t("voice.ss_voice")
        voice_controller = find('#ss-voice-controller-0')
        expect(voice_controller[:style]).to include("")
      end
    end
  end
end
