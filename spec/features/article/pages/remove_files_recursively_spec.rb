require 'spec_helper'

describe "article_pages remove_files_recursively", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:node) {
    create :article_node_page, filename: "docs", name: "article", state: "public", for_member_state: "disabled"
  }
  let!(:item) { create(:article_page, cur_node: node) }

  let(:edit_path) { edit_node_conf_path site.id, node }
  let(:delete_path) { delete_node_conf_path site.id, node }

  context "not changed" do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exist?(item.path)).to be true

      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(::File.exist?(item.path)).to be true
    end
  end

  context "state changed" do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exist?(item.path)).to be true

      visit edit_path

      within "form#item-form" do
        ensure_addon_opened '#addon-cms-agents-addons-release'
        within '#addon-cms-agents-addons-release' do
          select I18n.t("ss.options.state.closed"), from: "item[state]"
        end

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(::File.exist?(item.path)).to be false
    end
  end

  context "route changed" do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exist?(item.path)).to be true

      visit edit_path

      within "form#item-form" do
        wait_for_cbox_opened do
          click_link I18n.t("ss.links.change")
        end
      end
      within_cbox do
        click_link I18n.t("cms.nodes.ads/banner")
      end
      wait_for_js_ready
      within "form#item-form" do
        expect(page).to have_content "#{I18n.t("modules.ads")}/#{I18n.t("cms.nodes.ads/banner")}"

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(::File.exist?(item.path)).to be false
    end
  end

  context "for_member_state changed" do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exist?(item.path)).to be true

      visit edit_path
      within "form#item-form" do
        ensure_addon_opened '#addon-cms-agents-addons-for_member_node'
        within '#addon-cms-agents-addons-for_member_node' do
          select I18n.t("cms.options.member_state.enabled"), from: "item[for_member_state]"
        end

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      expect(::File.exist?(item.path)).to be false
    end
  end
end
