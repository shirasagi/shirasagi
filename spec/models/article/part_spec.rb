require 'spec_helper'

describe Article::Part::Page, type: :model, dbscope: :example do
  let(:item) { create :article_part_page }
  it_behaves_like "cms_part#spec"

  describe '#template_variable_get - name' do
    let(:page) { create(:article_page, name: 'ページ &') }

    it do
      expect(item.template_variable_get(page, 'name')).to eq('ページ &amp;')
    end
  end

  describe '#template_variable_get - url' do
    let(:page) { create(:article_page) }

    it do
      expect(item.template_variable_get(page, 'url')).to eq(page.url)
    end
  end

  describe '#template_variable_get - summary' do
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
      expect(item.template_variable_get(page, 'summary')).to eq('自治体サンプル 本文へ 文字サイズ小さく標準大きく 読み上げる ふりがなをつける ご利用案内')
    end
  end

  describe '#template_variable_get - class' do
    let(:page) { create(:article_page) }

    it do
      expect(item.template_variable_get(page, 'class')).to eq(page.basename.sub(/\..*/, "").dasherize)
    end
  end

  describe '#template_variable_get - new' do
    context 'new page' do
      let(:page) { create(:article_page) }

      it do
        expect(item.template_variable_get(page, 'new')).to eq('new')
      end
    end

    context 'not new page' do
      let(:page) { create(:article_page, released: Time.zone.now - 31.days) }

      it do
        expect(item.template_variable_get(page, 'new')).to be_nil
      end
    end
  end

  describe '#template_variable_get - date' do
    let(:page) { create(:article_page) }

    it 'date' do
      expect(item.template_variable_get(page, 'date')).to eq(I18n.l(page.date.to_date))
    end
    it 'date.default' do
      expect(item.template_variable_get(page, 'date.default')).to eq(I18n.l(page.date.to_date, format: :default))
    end
    it 'date.iso' do
      expect(item.template_variable_get(page, 'date.iso')).to eq(I18n.l(page.date.to_date, format: :iso))
    end
    it 'date.long' do
      expect(item.template_variable_get(page, 'date.long')).to eq(I18n.l(page.date.to_date, format: :long))
    end
    it 'date.short' do
      expect(item.template_variable_get(page, 'date.short')).to eq(I18n.l(page.date.to_date, format: :short))
    end
  end

  describe '#template_variable_get - time' do
    let(:page) { create(:article_page) }

    it 'time' do
      expect(item.template_variable_get(page, 'time')).to eq(I18n.l(page.date))
    end
    it 'time.default' do
      expect(item.template_variable_get(page, 'time.default')).to eq(I18n.l(page.date, format: :default))
    end
    it 'time.iso' do
      expect(item.template_variable_get(page, 'time.iso')).to eq(I18n.l(page.date, format: :iso))
    end
    it 'time.long' do
      expect(item.template_variable_get(page, 'time.long')).to eq(I18n.l(page.date, format: :long))
    end
    it 'time.short' do
      expect(item.template_variable_get(page, 'time.short')).to eq(I18n.l(page.date, format: :short))
    end
  end

  describe '#template_variable_get - group' do
    context 'no group' do
      let(:page) { create(:article_page) }

      it do
        expect(item.template_variable_get(page, 'group')).to eq('')
      end
    end

    context '1 group' do
      let(:group) { cms_group }
      let(:page) { create(:article_page, group_ids: [group.id]) }

      it do
        expect(item.template_variable_get(page, 'group')).to eq(group.name)
      end
    end
  end

  describe '#template_variable_get - groups' do
    context 'no group' do
      let(:page) { create(:article_page) }

      it do
        expect(item.template_variable_get(page, 'groups')).to eq('')
      end
    end

    context '1 group' do
      let(:group) { cms_group }
      let(:page) { create(:article_page, group_ids: [group.id]) }

      it do
        expect(item.template_variable_get(page, 'groups')).to eq(group.name)
      end
    end

    context '2 groups' do
      let(:group1) { cms_group }
      let(:group2) { create(:cms_group, name: 'グループ2') }
      let(:page) { create(:article_page, group_ids: [group1.id, group2.id]) }

      it do
        expect(item.template_variable_get(page, 'groups')).to eq("#{group1.name}, #{group2.name}")
      end
    end
  end
end
