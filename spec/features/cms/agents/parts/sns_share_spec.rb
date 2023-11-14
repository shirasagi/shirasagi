require 'spec_helper'

describe "cms_agents_parts_sns_share", type: :feature, dbscope: :example do
  context "public" do
    let(:site)   { cms_site }
    let(:layout) { create_cms_layout part }
    let(:node)   { create :cms_node, layout_id: layout.id }
    let(:part)   { create :cms_part_sns_share }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".cms-sns_share")
      expect(page).to have_css(".fb-like")
      expect(page).to have_css(".fb-share")
      expect(page).to have_css(".twitter")
      expect(page).to have_css(".hatena")
      expect(page).to have_css(".line")
    end
  end

  context "subsite" do
    let(:site0)   { cms_site }
    let(:site1)   { create(:cms_site_subdir, parent_id: site0.id) }
    let(:layout) { create_cms_layout part, site_id: site1.id }
    let(:node)   { create :cms_node, cur_site: site1, layout_id: layout.id }
    let(:part)   { create :cms_part_sns_share, cur_site: site1 }

    before do
      Capybara.app_host = "http://#{site1.domain}"
    end

    it do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css('.cms-sns_share')
      expect(page).to have_css('.fb-like')
      expect(page).to have_css('.fb-share')
      expect(page).to have_css('.twitter')
      expect(page).to have_css('.hatena')
      expect(page).to have_css('.line')
      expect(find('div.fb-like div.fb-like')['data-href']).to eq node.full_url[0..-2]
      within "div.twitter" do
        query = { url: node.full_url[0..-2], text: "#{node.name} -  #{site1.name}\r\n" }
        link = "https://twitter.com/share?#{query.to_query}"
        expect(page).to have_link(I18n.t("cms.sns_share.tweet"), href: link)
      end
    end
  end

  context "ajax_view is enabled", js: true do
    let(:site) { cms_site }
    let(:layout) { create_cms_layout part }
    let(:part) { create :cms_part_sns_share, cur_site: site, ajax_view: "enabled" }

    context "with node" do
      let(:node) { create :cms_node, cur_site: site, layout: layout }

      it do
        visit node.full_url
        expect(page).to have_css(".cms-sns_share")
        expect(page).to have_css(".fb-like")
        expect(page).to have_css(".fb-share")
        expect(page).to have_css(".twitter")
        expect(page).to have_css(".hatena")
        expect(page).to have_css(".line")
  
        within "div.twitter" do
          # AJAX が有効になっている場合、@window_name を取得できないので text にはページかフォルダーの名前のみがセットされている
          query = { url: node.full_url, text: "#{node.name}\r\n" }
          link = "https://twitter.com/share?#{query.to_query}"
          expect(page).to have_link(I18n.t("cms.sns_share.tweet"), href: link)
        end
      end
    end

    context "with page" do
      let(:article) { create :cms_page, cur_site: site, layout: layout }

      before do
        ::FileUtils.rm_f(article.path)
      end

      it do
        visit article.full_url
        expect(page).to have_css(".cms-sns_share")
        expect(page).to have_css(".fb-like")
        expect(page).to have_css(".fb-share")
        expect(page).to have_css(".twitter")
        expect(page).to have_css(".hatena")
        expect(page).to have_css(".line")

        within "div.twitter" do
          # AJAX が有効になっている場合、@window_name を取得できないので text にはページかフォルダーの名前のみがセットされている
          query = { url: article.full_url, text: "#{article.name}\r\n" }
          link = "https://twitter.com/share?#{query.to_query}"
          expect(page).to have_link(I18n.t("cms.sns_share.tweet"), href: link)
        end
      end
    end
  end
end
