require 'spec_helper'

describe "cms_node_nodes", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:node1) { create :cms_node }
  let!(:node2) { create :cms_node }
  let!(:node3) { create :cms_node }

  context "change state all", js: true do
    before { login_cms_user }

    it do
      visit cms_nodes_path(site)
      expect(node1.state).to eq "public"
      expect(node2.state).to eq "public"
      expect(node3.state).to eq "public"

      wait_event_to_fire("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_close')
      end

      wait_for_js_ready
      click_button I18n.t("ss.buttons.make_them_close")
      expect(current_path).to eq cms_nodes_path(site)

      node1.reload
      node2.reload
      node3.reload
      expect(node1.state).to eq "closed"
      expect(node2.state).to eq "closed"
      expect(node3.state).to eq "closed"

      wait_event_to_fire("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action-update" do
        click_button I18n.t('ss.links.make_them_public')
      end

      wait_for_js_ready
      click_button I18n.t("ss.buttons.make_them_public")
      expect(current_path).to eq cms_nodes_path(site)

      node1.reload
      node2.reload
      node3.reload
      expect(node1.state).to eq "public"
      expect(node2.state).to eq "public"
      expect(node3.state).to eq "public"
    end
  end
end
