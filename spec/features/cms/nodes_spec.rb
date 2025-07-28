require 'spec_helper'

describe "cms_nodes", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  context "basic crud" do
    before { login_cms_user }

    it do
      # new
      visit cms_nodes_path(site: site)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Cms::Node.all.count).to eq 1
      node = Cms::Node.all.first
      expect(node.site_id).to eq site.id
      expect(node.name).to eq "sample"
      expect(node.basename).to eq "sample"
      expect(node.filename).to eq "sample"
      expect(node.state).to eq "public"

      # show
      visit cms_node_path(site: site, id: node)

      # preview
      within "#addon-basic" do
        click_on I18n.t("ss.links.sp_preview")
      end
      switch_to_window(windows.last)
      wait_for_document_loading
      current_window.close if Capybara.javascript_driver == :chrome
      switch_to_window(windows.last)
      wait_for_document_loading

      # edit
      visit cms_node_path(site: site, id: node)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      node.reload
      expect(node.name).to eq "modify"

      # delete
      visit cms_node_path(site: site, id: node)
      click_on I18n.t("ss.links.delete")
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      wait_for_turbo_frame "#cms-nodes-tree-frame"

      expect { node.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "batch publish" do
    let!(:node1) { create :category_node_page, cur_site: site, state: "closed" }
    let!(:node2) { create :category_node_page, cur_site: site, state: "closed" }

    before { login_cms_user }

    it do
      visit cms_nodes_path(site: site)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      within ".list-head" do
        wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
        click_on I18n.t("ss.links.make_them_public")
      end
      within "form" do
        click_on I18n.t("ss.links.make_them_public")
      end
      wait_for_notice I18n.t("ss.notice.changed")
      wait_for_turbo_frame "#cms-nodes-tree-frame"

      Cms::Node.find(node1.id).tap do |node|
        expect(node.state).to eq "public"
      end
      Cms::Node.find(node2.id).tap do |node|
        expect(node.state).to eq "public"
      end
    end
  end

  context "batch close" do
    let!(:node1) { create :category_node_page, cur_site: site, state: "public" }
    let!(:node2) { create :category_node_page, cur_site: site, state: "public" }

    before { login_cms_user }

    it do
      visit cms_nodes_path(site: site)
      wait_for_turbo_frame "#cms-nodes-tree-frame"
      within ".list-head" do
        wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
        click_on I18n.t("ss.links.make_them_close")
      end
      within "form" do
        click_on I18n.t("ss.links.make_them_close")
      end
      wait_for_notice I18n.t("ss.notice.changed")
      wait_for_turbo_frame "#cms-nodes-tree-frame"

      Cms::Node.find(node1.id).tap do |node|
        expect(node.state).to eq "closed"
      end
      Cms::Node.find(node2.id).tap do |node|
        expect(node.state).to eq "closed"
      end
    end
  end
end
