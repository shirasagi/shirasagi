require 'spec_helper'

describe "cms_node_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:item) { create :cms_page, filename: "#{node.filename}/name" }
  let(:index_path)  { node_pages_path site.id, node }
  let(:new_path)    { "#{index_path}/new" }
  let(:show_path)   { "#{index_path}/#{item.id}" }
  let(:edit_path)   { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }

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
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it "#contains_urls" do
      visit contains_urls_node_page_path(site.id, node, item)
      expect(status_code).to eq 200
    end

    context "with branch", js: true do
      it "#contains_urls" do
        visit show_path
        within '#addon-workflow-agents-addons-branch' do
          click_on I18n.t("workflow.create_branch")
          expect(page).to have_link item.name
          click_on item.name
        end
        wait_for_ajax
        expect(page).to have_no_content I18n.t("cms.confirm.check_linked_url_list")
      end
    end
  end
end
