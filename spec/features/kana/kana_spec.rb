require 'spec_helper'

describe "kana/public_filter", type: :feature, dbscope: :example, js: true, mecab: true do
  let!(:site) { cms_site }

  shared_examples "kana" do
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

    describe "kana public filter" do
      it do
        visit item.full_url
        expect(page).to have_no_css('ruby')

        click_on 'ふりがなをつける'
        expect(page).to have_css('ruby')

        click_on 'ふりがなをはずす'
        expect(page).to have_no_css('ruby')
      end
    end

    context "site's kana format" do
      context "on default mode" do
        it do
          visit item.full_url
          click_on 'ふりがなをつける'
          expect(page).to have_css('ruby', text: '無償(むしょう)')
          expect(page).to have_css('ruby', text: '必要(ひつよう)')
          expect(page).to have_css('ruby', text: '場合(ばあい)')
          expect(page).to have_css('.percent-escaped-url', text: 'http%3A%2F%2F127.0.0.1%3A3000')
          expect(page).to have_content('PDFファイルをご覧(ごらん)いただくためには、')
        end
      end

      context "on hiragana mode" do
        before do
          site.kana_format = 'hiragana'
          site.save!
        end

        it do
          visit item.full_url
          click_on 'ふりがなをつける'
          expect(page).to have_css('ruby', text: '無償(むしょう)')
          expect(page).to have_css('ruby', text: '必要(ひつよう)')
          expect(page).to have_css('ruby', text: '場合(ばあい)')
        end
      end

      context "on katakana mode" do
        before do
          site.kana_format = 'katakana'
          site.save!
        end

        it do
          visit item.full_url
          click_on 'ふりがなをつける'
          expect(page).to have_css('ruby', text: '無償(ムショウ)')
          expect(page).to have_css('ruby', text: '必要(ヒツヨウ)')
          expect(page).to have_css('ruby', text: '場合(バアイ)')
        end
      end

      context "on romaji mode" do
        before do
          site.kana_format = 'romaji'
          site.save!
        end

        it do
          visit item.full_url
          click_on 'ふりがなをつける'
          expect(page).to have_css('ruby', text: '無償(mushou)')
          expect(page).to have_css('ruby', text: '必要(hitsuyou)')
          expect(page).to have_css('ruby', text: '場合(baai)')
        end
      end
    end

    context "with user dictionaries" do
      context "with tooltip's examples" do
        let(:user_dic_body) do
          body = []
          body << '大鷺県, ダイサギケン'
          body << '小鷺町, コサギマチ'
          body << 'SHIRASAGI, シラサギ'
          body << 'Shirasagi, シラサギ'
          body << 'shirasagi, シラサギ'
          body.join("\r\n")
        end
        let(:dic) { create :kana_dictionary, body: user_dic_body }

        before do
          Kana::Dictionary.build_dic(site.id, [ dic.id ])
        end

        it do
          visit item.full_url
          click_on 'ふりがなをつける'

          expect(page).to have_css('ruby', text: '大鷺県(だいさぎけん)')
          expect(page).to have_css('ruby', text: '小鷺町(こさぎまち)')
          expect(page).to have_css('ruby', text: 'Shirasagi(しらさぎ)')
        end
      end
    end

    context "with U+00A0(nbsp)" do
      let(:user_dic_body) do
        body = []
        body << 'AEON, イオン'
        body << 'MALL, モール'
        body << '大鷺県, ダイサギケン'
        body << '小鷺町, コサギマチ'
        body << 'SHIRASAGI, シラサギ'
        body << 'Shirasagi, シラサギ'
        body << 'shirasagi, シラサギ'
        body.join("\r\n")
      end
      let(:dic) { create :kana_dictionary, body: user_dic_body }
      let(:kana_url) { item.full_url.sub(node.url, SS.config.kana.location + node.url) }

      before do
        site.auto_description = 'enabled'
        site.auto_keywords = 'enabled'
        site.save!

        Kana::Dictionary.build_dic(site.id, [ dic.id ])

        item.name = "遂に「AEON\u00A0MALL」がシラサギ市にオープン"
        item.html = "<div><h2>遂に「AEON\u00A0MALL」がシラサギ市にオープン</h2></div>#{item.html}"
        item.save!

        FileUtils.rm_rf(item.path)
      end

      it do
        visit kana_url
        expect(page).to have_css('ruby', text: '大鷺県(だいさぎけん)')
      end
    end

    context "with kana-marks" do
      let(:kana_url) { item.full_url.sub(node.url, SS.config.kana.location + node.url) }

      before do
        site.auto_description = 'enabled'
        site.auto_keywords = 'enabled'
        site.save!

        item.html = [
          "<!-- write-kana --><div>上部</div><!-- end-write-kana -->",
          item.html,
          "<!-- write-kana --><div>下部</div><!-- end-write-kana -->"
        ].join
        item.save!

        FileUtils.rm_rf(item.path)
      end

      it do
        visit kana_url
        expect(page).to have_no_css('ruby', text: '無償(むしょう)')
        expect(page).to have_no_css('ruby', text: '必要(ひつよう)')
        expect(page).to have_no_css('ruby', text: '場合(ばあい)')
        expect(page).to have_css('ruby', text: '上部(じょうぶ)')
        expect(page).to have_css('ruby', text: '下部(かぶ)')
      end
    end

    context "with skip-marks" do
      let(:kana_url) { item.full_url.sub(node.url, SS.config.kana.location + node.url) }

      before do
        site.auto_description = 'enabled'
        site.auto_keywords = 'enabled'
        site.save!

        item.html = [
            "<!-- skip-kana --><div>上部</div><!-- end-skip-kana -->",
            item.html,
            "<!-- skip-kana --><div>下部</div><!-- end-skip-kana -->"
        ].join
        item.save!

        FileUtils.rm_rf(item.path)
      end

      it do
        visit kana_url
        expect(page).to have_css('ruby', text: '無償(むしょう)')
        expect(page).to have_css('ruby', text: '必要(ひつよう)')
        expect(page).to have_css('ruby', text: '場合(ばあい)')
        expect(page).to have_no_css('ruby', text: '上部(じょうぶ)')
        expect(page).to have_no_css('ruby', text: '下部(かぶ)')
      end
    end

    context "with write-marks and skip-marks" do
      let(:kana_url) { item.full_url.sub(node.url, SS.config.kana.location + node.url) }

      before do
        site.auto_description = 'enabled'
        site.auto_keywords = 'enabled'
        site.save!

        item.html = [
            "<!-- write-kana -->",
            "<!-- skip-kana --><div>上部</div><!-- end-skip-kana -->",
            item.html,
            "<!-- end-write-kana -->",
            "<div>下部</div>"
        ].join
        item.save!

        FileUtils.rm_rf(item.path)
      end

      it do
        visit kana_url
        expect(page).to have_css('ruby', text: '無償(むしょう)')
        expect(page).to have_css('ruby', text: '必要(ひつよう)')
        expect(page).to have_css('ruby', text: '場合(ばあい)')
        expect(page).to have_no_css('ruby', text: '上部(じょうぶ)')
        expect(page).to have_no_css('ruby', text: '下部(かぶ)')
      end
    end

    context "with link" do
      let(:user_dic_body) do
        body = []
        body << 'SHIRASAGI, シラサギ'
        body << 'Shirasagi, シラサギ'
        body << 'shirasagi, シラサギ'
        body.join("\r\n")
      end
      let(:dic) { create :kana_dictionary, body: user_dic_body }
      let(:kana_url) { item.full_url.sub(node.url, SS.config.kana.location + node.url) }

      before do
        site.auto_description = 'enabled'
        site.auto_keywords = 'enabled'
        site.save!

        Kana::Dictionary.build_dic(site.id, [ dic.id ])

        item.name = "SHIRASAGI 開発マニュアル"
        item.html = "<a href='https://shirasagi.github.io/'>SHIRASAGI 開発マニュアル</a>#{item.html}"
        item.save!

        FileUtils.rm_rf(item.path)
      end

      it do
        visit kana_url
        expect(page).to have_css('ruby', text: 'SHIRASAGI(しらさぎ)')
        expect(page).to have_css('ruby', text: '開発(かいはつ)')
        expect(page).to have_link(href: 'https://shirasagi.github.io/')
      end
    end
  end

  context "with latest accessibility html" do
    let!(:part) { create :accessibility_tool, cur_site: site }

    it_behaves_like "kana"
  end

  context "with old accessibility html" do
    let!(:part) { create :accessibility_tool_compat, cur_site: site }

    it_behaves_like "kana"
  end
end
