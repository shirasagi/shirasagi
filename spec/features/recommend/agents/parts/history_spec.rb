require 'spec_helper'

describe "recommend_agents_parts_history", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:part) { create :recommend_part_history, cur_site: site, substitute_html: "<p>no items</p>" }
  let!(:layout) { create_cms_layout part, cur_site: site }
  let!(:node) { create :cms_node_node, cur_site: site, layout_id: layout.id }
  let!(:article_page) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id }
  let!(:cms_page) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id }

  before do
    # delete all statically generated html files to dynamically respond contents
    ::FileUtils.rm_f("#{node.path}/index.html")
    ::FileUtils.rm_f(article_page.path)
    ::FileUtils.rm_f(cms_page.path)
  end

  after do
    SS.config.replace_value_at(:recommend, :disable, true)
  end

  context "public" do
    context "disable: false" do
      before do
        SS.config.replace_value_at(:recommend, :disable, false)
      end

      it "#index" do
        visit node.full_url
        within ".recommend-history" do
          expect(page).to have_content("no items")
          expect(page).to have_no_link(node.name, href: node.url)
          expect(page).to have_no_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end

        wait_for_ajax

        expect(Recommend::History::Log.count).to eq 1
        Recommend::History::Log.first.tap do |log|
          expect(log.token).not_to be_nil
          expect(log.path).to eq "#{node.url}index.html"
          expect(log.access_url).to eq node.full_url.to_s
          expect(log.target_id).to eq node.id.to_s
          expect(log.target_class).to eq node.class.to_s
          expect(log.remote_addr).to eq "127.0.0.1"
          expect(log.user_agent).not_to be_nil
        end

        visit article_page.full_url
        within ".recommend-history" do
          expect(page).to have_link(node.name, href: node.url)
          expect(page).to have_no_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end

        wait_for_ajax

        expect(Recommend::History::Log.count).to eq 2
        Recommend::History::Log.order_by(created: -1).first.tap do |log|
          expect(log.token).not_to be_nil
          expect(log.path).to eq article_page.url
          expect(log.access_url).to eq article_page.full_url
          expect(log.target_id).to eq article_page.id.to_s
          expect(log.target_class).to eq article_page.class.to_s
          expect(log.remote_addr).to eq "127.0.0.1"
          expect(log.user_agent).not_to be_nil
        end

        visit cms_page.full_url
        within ".recommend-history" do
          expect(page).to have_link(node.name, href: node.url)
          expect(page).to have_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end

        wait_for_ajax

        expect(Recommend::History::Log.count).to eq 3
        Recommend::History::Log.order_by(created: -1).first.tap do |log|
          expect(log.token).not_to be_nil
          expect(log.path).to eq cms_page.url
          expect(log.access_url).to eq cms_page.full_url
          expect(log.target_id).to eq cms_page.id.to_s
          expect(log.target_class).to eq cms_page.class.to_s
          expect(log.remote_addr).to eq "127.0.0.1"
          expect(log.user_agent).not_to be_nil
        end

        visit part.full_url
        within ".recommend-history" do
          expect(page).to have_link(node.name, href: node.url)
          expect(page).to have_link(article_page.name, href: article_page.url)
          expect(page).to have_link(cms_page.name, href: cms_page.url)
        end
      end
    end

    context "disable: true" do
      before do
        SS.config.replace_value_at(:recommend, :disable, true)
      end

      it "#index" do
        visit node.full_url
        within ".recommend-history" do
          expect(page).to have_content("no items")
          expect(page).to have_no_link(node.name, href: node.url)
          expect(page).to have_no_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end

        visit article_page.full_url
        within ".recommend-history" do
          expect(page).to have_content("no items")
          expect(page).to have_no_link(node.name, href: node.url)
          expect(page).to have_no_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end

        visit cms_page.full_url
        within ".recommend-history" do
          expect(page).to have_content("no items")
          expect(page).to have_no_link(node.name, href: node.url)
          expect(page).to have_no_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end

        visit part.full_url
        within ".recommend-history" do
          expect(page).to have_content("no items")
          expect(page).to have_no_link(node.name, href: node.url)
          expect(page).to have_no_link(article_page.name, href: article_page.url)
          expect(page).to have_no_link(cms_page.name, href: cms_page.url)
        end
      end
    end
  end

  context "with exclude_paths" do
    before do
      SS.config.replace_value_at(:recommend, :disable, false)

      part.update(exclude_paths: [ article_page.url ])
    end

    it do
      visit node.full_url
      within ".recommend-history" do
        expect(page).to have_content("no items")
        expect(page).to have_no_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)
      end

      visit article_page.full_url
      within ".recommend-history" do
        expect(page).to have_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)
      end

      visit cms_page.full_url
      within ".recommend-history" do
        expect(page).to have_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)
      end

      visit node.full_url
      within ".recommend-history" do
        expect(page).to have_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_link(cms_page.name, href: cms_page.url)
      end
    end
  end
end
