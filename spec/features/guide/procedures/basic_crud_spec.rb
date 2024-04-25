require 'spec_helper'

describe "guide_procedures", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node)   { create :guide_node_guide, filename: "guide" }
  let(:item) { create(:guide_procedure, cur_site: site, cur_node: node) }

  let(:index_path) { guide_procedures_path site.id, node }
  let(:new_path) { new_guide_procedure_path site.id, node }
  let(:show_path) { guide_procedure_path site.id, node, item }
  let(:edit_path) { edit_guide_procedure_path site.id, node, item }
  let(:delete_path) { delete_guide_procedure_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[id_name]", with: "0.sample"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#show" do
      visit show_path

      within "#addon-basic" do
        expect(page).to have_text(item.name)
        expect(page).to have_text(item.link_url)
      end
      within "#addon-guide-agents-addons-procedure" do
        expect(page).to have_text("location1")
        expect(page).to have_text("belong1")
        expect(page).to have_text("applicant1")
        expect(page).to have_text("remarks")
      end
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        fill_in "item[name]", with: "0.modify"
        fill_in "item[link_url]", with: "https://modify.example.jp"
        fill_in_code_mirror "item[html]", with: "<p>modify_html</p>"
        fill_in "item[procedure_location]", with: "modify_location1"
        fill_in "item[belongings]", with: "modify_belong1"
        fill_in "item[procedure_applicant]", with: "modify_applicant1"
        fill_in "item[remarks]", with: "modify_remarks"
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within "#addon-basic" do
        expect(page).to have_text("modify")
        expect(page).to have_text("https://modify.example.jp")
      end
      within "#addon-guide-agents-addons-procedure" do
        expect(page).to have_text("modify_html")
        expect(page).to have_text("modify_location1")
        expect(page).to have_text("modify_belong1")
        expect(page).to have_text("modify_applicant1")
        expect(page).to have_text("modify_remarks")
      end
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
