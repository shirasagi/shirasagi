require 'spec_helper'

describe "node_max_file_sizes", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:site_admin) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site, group_ids: site_admin.group_ids }

  let(:name) { "name-#{unique_id}" }
  let(:extensions) { Array.new(rand(2..3)) { "ext-#{unique_id}" } }
  let(:size_mb) { rand(5..8) }
  let(:size) { size_mb * 1_024 * 1_024 }
  let(:order) { rand(11..20) }
  let(:state) { %w(enabled disabled).sample }
  let(:state_label) { I18n.t("ss.options.state.#{state}") }

  let(:name2) { "name-#{unique_id}" }
  let(:extensions2) { Array.new(rand(2..3)) { "ext-#{unique_id}" } }
  let(:size_mb2) { rand(5..8) }
  let(:size2) { size_mb2 * 1_024 * 1_024 }
  let(:order2) { rand(11..20) }
  let(:state2) { %w(enabled disabled).sample }
  let(:state_label2) { I18n.t("ss.options.state.#{state2}") }

  context "basic crud" do
    it do
      login_user site_admin, to: article_pages_path(site: site, cid: node)
      within first("#main .main-navi") do
        click_on I18n.t("cms.node_config")
      end

      ensure_addon_opened "#addon-cms-agents-addons-max_file_size_setting"
      within "#addon-cms-agents-addons-max_file_size_setting" do
        click_on I18n.t("cms.add_max_file_size")
      end

      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[extensions]", with: extensions.join(" ")
        fill_in "item[in_size_mb]", with: size_mb
        fill_in "item[order]", with: order
        select state_label, from: "item[state]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Cms::MaxFileSize.all.count).to eq 1
      Cms::MaxFileSize.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.node_id).to eq node.id
        expect(item.name).to eq name
        expect(item.extensions).to eq extensions
        expect(item.size).to eq size
        expect(item.order).to eq order
        expect(item.state).to eq state
      end

      visit node_max_file_sizes_path(site: site, cid: node)
      expect(page).to have_css(".list-item", text: name)
      click_on name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in "item[extensions]", with: extensions2.join(" ")
        fill_in "item[in_size_mb]", with: size_mb2
        fill_in "item[order]", with: order2
        select state_label2, from: "item[state]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Cms::MaxFileSize.all.count).to eq 1
      Cms::MaxFileSize.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.node_id).to eq node.id
        expect(item.name).to eq name2
        expect(item.extensions).to eq extensions2
        expect(item.size).to eq size2
        expect(item.order).to eq order2
        expect(item.state).to eq state2
      end

      visit node_max_file_sizes_path(site: site, cid: node)
      expect(page).to have_css(".list-item", text: name2)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Cms::MaxFileSize.all.count).to eq 0
    end
  end
end
