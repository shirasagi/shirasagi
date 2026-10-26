require 'spec_helper'

describe 'article_agents_pages_page', type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create(:article_node_page, cur_site: site, layout: layout) }
  let!(:item1) { create(:article_page, cur_site: site, cur_node: node) }
  let!(:item2) { create(:article_page, cur_site: site, cur_node: node, redirect_link: redirect_link) }

  context "when redirect_link_state is enabled" do
    before do
      site.update!(redirect_link_state: "enabled")

      FileUtils.rm_rf(node.path)
      FileUtils.rm_rf(item1.path)
      FileUtils.rm_rf(item2.path)
    end

    context "redirect url" do
      let(:redirect_link) { item1.url }
      let(:item2_original_url) { "/#{item2.filename}" }

      before do
        Capybara.app_host = "http://#{site.domain}"
      end

      it do
        expect(item1.url).to eq item2.url

        visit item1.url
        expect(current_path).to eq item1.url

        visit item2_original_url
        expect(current_path).to eq item1.url

        visit node.url
        click_on item1.name
        expect(current_path).to eq item1.url

        visit node.url
        click_on item2.name
        expect(current_path).to eq item1.url
      end
    end

    context "redirect full url" do
      let(:redirect_link) { item1.full_url }
      let(:item2_original_full_url) { "http://#{site.domain}/#{item2.filename}" }

      before do
        # Capybara.app_host = "http://#{site.domain}"
      end

      it do
        expect(item1.full_url).to eq item2.full_url

        visit item1.full_url
        expect("http://#{site.domain}#{current_path}").to eq item1.full_url

        visit item2_original_full_url
        expect("http://#{site.domain}#{current_path}").to eq item1.full_url

        visit node.url
        click_on item1.name
        expect("http://#{site.domain}#{current_path}").to eq item1.full_url

        visit node.url
        click_on item2.name
        expect("http://#{site.domain}#{current_path}").to eq item1.full_url
      end
    end
  end

  context "when redirect_link_state is disabled" do
    before do
      site.update!(redirect_link_state: "disabled")

      FileUtils.rm_rf(node.path)
      FileUtils.rm_rf(item1.path)
      FileUtils.rm_rf(item2.path)
    end

    context "redirect url" do
      let(:redirect_link) { item1.url }
      let(:item2_original_url) { "/#{item2.filename}" }

      before do
        Capybara.app_host = "http://#{site.domain}"
      end

      it do
        expect(item1.url).not_to eq item2.url

        visit item1.url
        expect(current_path).to eq item1.url

        visit item2_original_url
        expect(current_path).to eq item2.url

        visit node.url
        click_on item1.name
        expect(current_path).to eq item1.url

        visit node.url
        click_on item2.name
        expect(current_path).to eq item2.url
      end
    end

    context "redirect full url" do
      let(:redirect_link) { item1.full_url }
      let(:item2_original_full_url) { "http://#{site.domain}/#{item2.filename}" }

      it do
        expect(item1.full_url).not_to eq item2.full_url

        visit item1.full_url
        expect("http://#{site.domain}#{current_path}").to eq item1.full_url

        visit item2_original_full_url
        expect("http://#{site.domain}#{current_path}").to eq item2.full_url

        visit node.url
        click_on item1.name
        expect("http://#{site.domain}#{current_path}").to eq item1.full_url

        visit node.url
        click_on item2.name
        expect("http://#{site.domain}#{current_path}").to eq item2.full_url
      end
    end
  end
end
