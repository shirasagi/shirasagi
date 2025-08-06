require 'spec_helper'

describe "member_agents_parts_logins", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout part }
  let(:node)   { create :cms_node, layout_id: layout.id }
  let(:part)   { create :member_part_login, ajax_view: 'enabled' }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      wait_for_js_ready
      wait_for_all_ajax_parts
      expect(page).to have_no_css(".ss-part")
      expect(page).to have_css(".login")
    end

    context "when part state is closed" do
      before do
        Cms::Node::GenerateJob.bind(site_id: site.id, node_id: node.id).perform_now
        part.state = 'closed'
        part.save!
      end

      around do |example|
        Capybara.raise_server_errors = false
        example.run
        Capybara.raise_server_errors = true
      end

      it "#index" do
        visit node.url
        wait_for_js_ready
        wait_for_all_ajax_parts
        expect(page).to have_css('div#main')
        expect(page).to have_no_css(".ss-part")
        expect(page).to have_no_css(".login")
      end
    end
  end

  context "sub site" do
    let!(:site1) { create(:cms_site_subdir, parent_id: site.id) }

    let!(:layout1) { create_cms_layout cur_site: site1 }
    let!(:login_node1) { create :member_node_login, cur_site: site1, layout: layout1, redirect_url: "/#{unique_id}/#{unique_id}/" }
    let!(:login_part1) { create :member_part_login, cur_site: site1, cur_node: login_node1, ajax_view: 'enabled' }

    let!(:layout2) { create_cms_layout login_part1, cur_site: site1 }
    let!(:node1) { create :cms_node, cur_site: site1, layout: layout2 }
    let!(:mypage_node1) { create :member_node_mypage, cur_site: site1, layout: layout2 }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node1.url
      wait_for_js_ready
      wait_for_all_ajax_parts
      expect(page).to have_no_css(".ss-part")
      expect(page).to have_css(".login", text: I18n.t("ss.login"))
      expect(page).to have_link(I18n.t("ss.login"), href: login_node1.url)
    end
  end
end
