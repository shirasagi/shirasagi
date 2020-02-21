require 'spec_helper'

describe "garbage_node_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :garbage_node_node }
  let(:item) { create :garbage_node_page, filename: "#{node.filename}/name" }

  let(:index_path) { garbage_nodes_path site.id, node }
  let(:new_path) { new_garbage_node_path site.id, node }
  let(:show_path) { garbage_node_path site.id, node, item }
  let(:edit_path) { edit_garbage_node_path site.id, node, item }
  let(:delete_path) { delete_garbage_node_path site.id, node, item }
  let(:import_path) { import_garbage_nodes_path site.id, node }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "#import" do
      visit import_path

      within "form#task-form" do
        attach_file "item[file]", "#{Rails.root}/spec/fixtures/garbage/garbage_pages.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end
      expect(page).to have_content I18n.t("ss.notice.started_import")
    end
  end
end
