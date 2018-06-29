require 'spec_helper'

describe "recommend_agents_parts_history", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout part }
  let!(:part) { create :recommend_part_history, filename: "node/part" }
  let!(:node) { create :cms_node_node, layout_id: layout.id, filename: "node" }
  let!(:article_page) { create :article_page, layout_id: layout.id, filename: "node/article_page.html" }
  let!(:cms_page) { create :article_page, layout_id: layout.id, filename: "node/cms_page.html" }

  context "public" do
    context "disable: false" do
      before do
        SS.config.replace_value_at(:recommend, :disable, false)

        # https://jira.mongodb.org/browse/MONGOID-4544
        #article_page.touch
        article_page.save!

        # https://jira.mongodb.org/browse/MONGOID-4544
        #cms_page.touch
        cms_page.save!
      end

      after do
        SS.config.replace_value_at(:recommend, :disable, true)
      end

      it "#index" do
        visit node.full_url
        expect(page).to have_css(".recommend-history")
        expect(page).to have_no_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)

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
        expect(page).to have_css(".recommend-history")
        expect(page).to have_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)

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
        expect(page).to have_css(".recommend-history")
        expect(page).to have_link(node.name, href: node.url)
        expect(page).to have_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)

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
        expect(page).to have_css(".recommend-history")
        expect(page).to have_link(node.name, href: node.url)
        expect(page).to have_link(article_page.name, href: article_page.url)
        expect(page).to have_link(cms_page.name, href: cms_page.url)
      end
    end

    context "disable: true" do
      before do
        SS.config.replace_value_at(:recommend, :disable, true)

        # https://jira.mongodb.org/browse/MONGOID-4544
        #article_page.touch
        article_page.save!

        # https://jira.mongodb.org/browse/MONGOID-4544
        #cms_page.touch
        cms_page.save!
      end

      it "#index" do
        visit node.full_url
        expect(page).to have_css(".recommend-history")
        expect(page).to have_no_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)

        visit article_page.full_url
        expect(page).to have_css(".recommend-history")
        expect(page).to have_no_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)

        visit cms_page.full_url
        expect(page).to have_css(".recommend-history")
        expect(page).to have_no_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)

        visit part.full_url
        expect(page).to have_css(".recommend-history")
        expect(page).to have_no_link(node.name, href: node.url)
        expect(page).to have_no_link(article_page.name, href: article_page.url)
        expect(page).to have_no_link(cms_page.name, href: cms_page.url)
      end
    end
  end
end
