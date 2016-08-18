require 'spec_helper'

describe "kana/public_filter", type: :feature, dbscope: :example, js: true, mecab: true do
  let(:site) { cms_site }
  let(:part_html) { '<div id="tool"><nav><span id="ss-kana">ふりがなをつける</span></nav></div>' }
  let(:part) { create :cms_part_free, cur_site: site, filename: "tool", html: part_html }
  let(:layout) { create_cms_layout [part] }
  let(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
  let(:page_html) do
    html = []
    html << '<div id="content">'
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
  let(:item) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: page_html }

  describe "kana public filter" do
    it do
      visit item.full_url
      expect(page).not_to have_css('ruby')

      click_on 'ふりがなをつける'
      puts page.html
      expect(page).to have_css('ruby')

      click_on 'ふりがなをはずす'
      expect(page).not_to have_css('ruby')
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
end
