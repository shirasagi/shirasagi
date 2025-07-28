require 'spec_helper'

describe "cms_node_nodes", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node0) { create :cms_node, cur_site: site }
  let!(:node1) { create :cms_node, cur_site: site, cur_node: node0 }
  let!(:node2) { create :cms_node, cur_site: site, cur_node: node0 }
  let!(:node3) { create :cms_node, cur_site: site, cur_node: node0 }

  context "change state all" do
    before { login_cms_user }

    it do
      visit node_nodes_path(site: site, cid: node0)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      expect(node1.state).to eq "public"
      expect(node2.state).to eq "public"
      expect(node3.state).to eq "public"

      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_close')
      end

      wait_for_js_ready
      within "form" do
        click_button I18n.t("ss.buttons.make_them_close")
      end
      wait_for_notice I18n.t("ss.notice.changed")
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      expect(current_path).to eq node_nodes_path(site: site, cid: node0)

      node1.reload
      node2.reload
      node3.reload
      expect(node1.state).to eq "closed"
      expect(node2.state).to eq "closed"
      expect(node3.state).to eq "closed"

      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_public')
      end

      wait_for_js_ready
      within "form" do
        click_button I18n.t("ss.buttons.make_them_public")
      end
      wait_for_notice I18n.t("ss.notice.changed")
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      expect(current_path).to eq node_nodes_path(site: site, cid: node0)

      node1.reload
      node2.reload
      node3.reload
      expect(node1.state).to eq "public"
      expect(node2.state).to eq "public"
      expect(node3.state).to eq "public"
    end
  end
end
