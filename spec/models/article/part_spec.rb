require 'spec_helper'

describe Article::Part::Page, type: :model, dbscope: :example do
  let(:item) { create :article_part_page }
  it_behaves_like "cms_part#spec_detail"

  describe "validation" do
    it "basename" do
      item = build(:article_part_page_basename_invalid)
      expect(item.invalid?).to be_truthy
    end
  end

  describe '#render_loop_html - id' do
    let(:page) { create(:article_page, name: 'ページ &') }

    it do
      expect(item.render_loop_html(page, html: '#{id}')).to eq(page.id.to_s)
    end
  end

  describe '#render_loop_html - name' do
    let(:page) { create(:article_page, name: 'ページ &') }

    it do
      expect(item.render_loop_html(page, html: '#{name}')).to eq('ページ &amp;')
    end
  end

  describe '#render_loop_html - url' do
    let(:page) { create(:article_page) }

    it do
      expect(item.render_loop_html(page, html: '#{url}')).to eq(page.url)
    end
  end

  describe '#render_loop_html - summary' do
    context 'usual case' do
      let(:html) do
        <<-HTML
          <!doctype html>
          <html xmlns="http://www.w3.org/1999/xhtml" lang="ja">

          <head>
          <meta charset="UTF-8" />
          <title>自治体サンプル</title>
          <link rel="stylesheet" media="screen" href="/assets/cms/public.css" />
          <script src="/assets/cms/public.js"></script>

            <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes,minimum-scale=1.0,maximum-scale=2.0">
            <link href="/css/style.css" media="all" rel="stylesheet" }}
            <script src="/js/common.js"></script>
            <!--[if lt IE 9]>
            <script src="/js/selectivizr.js"></script>
            <script src="/js/html5shiv.js"></script>
            <![endif]-->


          </head>

          <body id="body--index" class="">
          <div id="page">

          <div id="tool">
          <nav>
            <a id="nocssread" href="#wrap">本文へ</a>
            <div id="size">文字サイズ<span id="ss-small">小さく</span><span id="ss-medium">標準</span><span id="ss-large">大きく</span></div>
            <span id="ss-voice">読み上げる</span>
            <span id="ss-kana">ふりがなをつける</span>
            <a id="info" href="/use/">ご利用案内</a>
          </nav>
          </div>
        HTML
      end
      let(:page) { create(:article_page, html: html) }

      it do
        expect(item.render_loop_html(page, html: '#{summary}')).to eq('自治体サンプル 本文へ 文字サイズ小さく標準大きく 読み上げる ふりがなをつける ご利用案内')
      end
    end

    context 'html and summary is nil' do
      let(:page) { create(:article_page, summary_html: nil, html: nil) }

      it do
        expect(item.render_loop_html(page, html: '#{summary}')).to eq('')
      end
    end
  end

  describe '#render_loop_html - class' do
    let(:page) { create(:article_page) }

    it do
      expect(item.render_loop_html(page, html: '#{class}')).to eq(page.basename.sub(/\..*/, "").dasherize)
    end
  end

  describe '#render_loop_html - new' do
    context 'new page' do
      let(:page) { create(:article_page) }

      it do
        expect(item.render_loop_html(page, html: '#{new}')).to eq('new')
      end
    end

    context 'not new page' do
      let(:page) { create(:article_page, released: Time.zone.now - 31.days) }

      it do
        expect(item.render_loop_html(page, html: '#{new}')).to eq ''
      end
    end
  end

  describe '#render_loop_html - date' do
    let(:page) { create(:article_page) }

    it 'date' do
      expect(item.render_loop_html(page, html: '#{date}')).to eq(I18n.l(page.date.to_date))
    end
    it 'date.default' do
      expect(item.render_loop_html(page, html: '#{date.default}')).to eq(I18n.l(page.date.to_date, format: :default))
    end
    it 'date.iso' do
      expect(item.render_loop_html(page, html: '#{date.iso}')).to eq(I18n.l(page.date.to_date, format: :iso))
    end
    it 'date.long' do
      expect(item.render_loop_html(page, html: '#{date.long}')).to eq(I18n.l(page.date.to_date, format: :long))
    end
    it 'date.short' do
      expect(item.render_loop_html(page, html: '#{date.short}')).to eq(I18n.l(page.date.to_date, format: :short))
    end
  end

  describe '#render_loop_html - time' do
    let(:page) { create(:article_page) }

    it 'time' do
      expect(item.render_loop_html(page, html: '#{time}')).to eq(I18n.l(page.date))
    end
    it 'time.default' do
      expect(item.render_loop_html(page, html: '#{time.default}')).to eq(I18n.l(page.date, format: :default))
    end
    it 'time.iso' do
      expect(item.render_loop_html(page, html: '#{time.iso}')).to eq(I18n.l(page.date, format: :iso))
    end
    it 'time.long' do
      expect(item.render_loop_html(page, html: '#{time.long}')).to eq(I18n.l(page.date, format: :long))
    end
    it 'time.short' do
      expect(item.render_loop_html(page, html: '#{time.short}')).to eq(I18n.l(page.date, format: :short))
    end
  end

  describe '#render_loop_html - group' do
    context 'no group' do
      let(:page) { create(:article_page) }

      it do
        expect(item.render_loop_html(page, html: '#{group}')).to eq('')
      end
    end

    context '1 group' do
      let(:group) { cms_group }
      let(:page) { create(:article_page, group_ids: [group.id]) }

      it do
        expect(item.render_loop_html(page, html: '#{group}')).to eq(group.name)
      end
    end
  end

  describe '#render_loop_html - groups' do
    context 'no group' do
      let(:page) { create(:article_page) }

      it do
        expect(item.render_loop_html(page, html: '#{groups}')).to eq('')
      end
    end

    context '1 group' do
      let(:group) { cms_group }
      let(:page) { create(:article_page, group_ids: [group.id]) }

      it do
        expect(item.render_loop_html(page, html: '#{groups}')).to eq(group.name)
      end
    end

    context '2 groups' do
      let(:group1) { cms_group }
      let(:group2) { create(:cms_group, name: 'グループ2') }
      let(:page) { create(:article_page, group_ids: [group1.id, group2.id]) }

      it do
        expect(item.render_loop_html(page, html: '#{groups}')).to eq("#{group1.name}, #{group2.name}")
      end
    end
  end

  describe '#render_loop_html - current' do
    let(:page) { create(:article_page) }

    it do
      expect(item.render_loop_html(page, html: '#{current}')).to eq('#{current}')
    end
  end

  describe '#render_loop_html - categories' do
    context 'empty categories' do
      let(:page) { create(:article_page) }

      it do
        expect(item.render_loop_html(page, html: '#{categories}')).to eq('')
      end
    end

    context '1 category' do
      let(:node_category) { create :category_node_page }
      let(:page) { create(:article_page, category_ids: [ node_category.id ]) }

      it do
        expect(item.render_loop_html(page, html: '#{categories}')).to \
          eq("<span class=\"#{node_category.filename}\"><a href=\"#{node_category.url}\">#{node_category.name}</a></span>")
      end
    end

    context '2 categories' do
      let(:node_category1) { create :category_node_page }
      let(:node_category2) { create :category_node_page }
      let(:page) { create(:article_page, category_ids: [ node_category1.id, node_category2.id ]) }

      it do
        expect(item.render_loop_html(page, html: '#{categories}')).to \
          include(
            "<span class=\"#{node_category1.filename}\"><a href=\"#{node_category1.url}\">#{node_category1.name}</a></span>",
            "<span class=\"#{node_category2.filename}\"><a href=\"#{node_category2.url}\">#{node_category2.name}</a></span>"
          )
      end
    end
  end

  describe '#render_loop_html - pages.count' do
    let!(:root_category) { create(:category_node_node) }
    let!(:node_category) { create(:category_node_page, cur_node: root_category) }
    let!(:node_article) { create(:article_node_page) }
    let!(:page) { create(:article_page, cur_node: node_article, category_ids: [ node_category.id ]) }

    context 'pages.count on the page' do
      it do
        expect(item.render_loop_html(page, html: '#{pages.count}')).to eq('')
      end
    end

    context 'node contains 1 page' do
      it do
        expect(item.render_loop_html(node_article, html: '#{pages.count}')).to eq('1')
      end
    end

    context 'node related to 1 page' do
      it do
        expect(item.render_loop_html(node_category, html: '#{pages.count}')).to eq('1')
      end
    end

    context 'node contains no pages' do
      it do
        expect(item.render_loop_html(root_category, html: '#{pages.count}')).to eq('0')
      end
    end
  end

  describe '#render_loop_html - html' do
    context 'no html' do
      let(:page) { create(:article_page) }

      it do
        expect(item.render_loop_html(page, html: '#{html}')).to eq('')
      end
    end

    context 'a html' do
      let(:page) { create(:article_page, html: '<h1>Hello,&nbsp;Shirasagi!</h1>') }

      it do
        expect(item.render_loop_html(page, html: '#{html}')).to eq('<h1>Hello,&nbsp;Shirasagi!</h1>')
      end
    end
  end

  describe '#render_loop_html - img.src' do
    context 'no html' do
      let(:page) { create(:article_page) }

      it do
        expect(item.render_loop_html(page, html: '#{img.src}')).to eq('/assets/img/dummy.png')
      end
    end

    context 'html contains <img>' do
      let(:html) { '<img src="/fs/1/0/2/_/512px-Ghostscript_Tiger_svg.png" alt="Tiger">' }
      let(:page) { create(:article_page, html: html) }

      it do
        expect(item.render_loop_html(page, html: '#{img.src}')).to eq('/fs/1/0/2/_/512px-Ghostscript_Tiger_svg.png')
      end
    end

    context 'img source is relative path' do
      let(:node) { create(:article_node_page) }
      let(:page) { create(:article_page, cur_node: node, html: '<img src="../img/logo.png">') }

      it do
        expect(item.render_loop_html(page, html: '#{img.src}')).to eq("#{File.dirname(page.url)}/../img/logo.png")
      end
    end

    context 'img source is external path' do
      let(:html) { '<img src="https://b.st-hatena.com/images/entry-button/button-only@2x.png">' }
      let(:page) { create(:article_page, html: html) }

      it do
        expect(item.render_loop_html(page, html: '#{img.src}')).to eq('https://b.st-hatena.com/images/entry-button/button-only@2x.png')
      end
    end

    context 'img source is external path without protocol' do
      let(:html) { '<img src="//b.st-hatena.com/images/entry-button/button-only@2x.png">' }
      let(:page) { create(:article_page, html: html) }

      it do
        expect(item.render_loop_html(page, html: '#{img.src}')).to eq('//b.st-hatena.com/images/entry-button/button-only@2x.png')
      end
    end

    context 'body parts contains <img>' do
      let(:body_layout) { create(:cms_body_layout) }
      let(:page) do
        create(:article_page, body_layout_id: body_layout.id,
               body_parts: ['<img src="/fs/1/0/2/_/512px-Ghostscript_Tiger_svg.png" alt="Tiger">'])
      end

      it do
        expect(item.render_loop_html(page, html: '#{img.src}')).to eq('/fs/1/0/2/_/512px-Ghostscript_Tiger_svg.png')
      end
    end
  end

  describe "what article/part/page exports to liquid" do
    let(:assigns) { { "parts" => SS::LiquidPartDrop.get(cms_site) } }
    let(:registers) { { cur_site: cms_site, cur_part: part, cur_path: page.url } }
    let(:node) { create :article_node_page }
    let(:page) { create :article_page, cur_node: node }
    subject { part.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "with Cms::Content" do
      let!(:released) { Time.zone.now.change(min: rand(0..59)) }
      let!(:part) { create :article_part_page, cur_node: node, index_name: unique_id, released: released }

      it do
        # Cms::Content
        expect(subject.id).to eq part.id
        expect(subject.name).to eq part.name
        expect(subject.url).to eq part.url
        expect(subject.full_url).to eq part.full_url
        expect(subject.basename).to eq part.basename
        expect(subject.filename).to eq part.filename
        expect(subject.parent.id).to eq node.id

        # undocument, but supported
        expect(subject.index_name).to eq part.index_name
        expect(subject.order).to eq part.order
        expect(subject.date).to eq part.date
        expect(subject.released).to eq part.released
        expect(subject.updated).to eq part.updated
        expect(subject.created).to eq part.created
        expect(subject.css_class).to eq part.basename.sub(".part.html", "").dasherize
        expect(subject.new?).to be_truthy
        expect(subject.current?).to be_falsey
      end
    end

    context "with Cms::Model::Part" do
      context "with shirasagi format" do
        let!(:upper_html) { '<div class="middle dw">' }
        let!(:loop_html) { '<div><h2><a href="#{url}">#{index_name}</a></h2></div>' }
        let!(:lower_html) { '</div>' }
        let!(:part) do
          create(
            :article_part_page, cur_node: node, loop_format: "shirasagi",
            upper_html: upper_html, loop_html: loop_html, lower_html: lower_html
          )
        end

        it do
          expected = []
          expected << '<div class="article-pages pages">'
          expected << '<div class="middle dw">'
          expected << "<div><h2><a href=\"#{page.url}\">#{page.name}</a></h2></div>"
          expected << '</div>'
          expected << '</div>'
          expect(subject.html.strip).to eq expected.join("\n").strip
        end
      end

      context "with liquid format" do
        let!(:loop_liquid) do
          templ = []
          templ << '<div class="middle dw">'
          templ << '{% for page in pages %}'
          templ << '<div><h2><a href="{{ page.url }}">{{ page.index_name | default: page.name }}</a></h2></div>'
          templ << '{% endfor %}'
          templ << '</div>'
          templ.join("\n")
        end
        let!(:part) do
          create(:article_part_page, cur_node: node, loop_format: "liquid", loop_liquid: loop_liquid)
        end

        it do
          expected = []
          expected << '<div class="article-pages pages">'
          expected << '<div class="middle dw">'
          expected << ''
          expected << "<div><h2><a href=\"#{page.url}\">#{page.name}</a></h2></div>"
          expected << ''
          expected << '</div>'
          expected << '</div>'
          expect(subject.html.strip).to eq expected.join("\n").strip
        end
      end
    end
  end
end
