require 'spec_helper'

describe "guide_questions", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node)   { create :guide_node_guide, filename: "guide" }
  let(:item) { create(:guide_question, cur_site: site, cur_node: node) }

  let(:index_path) { guide_questions_path site.id, node }
  let(:new_path) { new_guide_question_path site.id, node }
  let(:show_path) { guide_question_path site.id, node, item }
  let(:edit_path) { edit_guide_question_path site.id, node, item }
  let(:delete_path) { delete_guide_question_path site.id, node, item }

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
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
      expect(page).to have_css("#addon-guide-agents-addons-question", text: I18n.t("guide.options.question_type.yes_no"))
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        fill_in "item[id_name]", with: "0.modify"
        choose "item_question_type_choices"
        choose "item_check_type_single"
        fill_in "item[in_edges][][value]", with: "answer1"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(page).to have_css("#addon-basic", text: "modify")
      expect(page).to have_css("#addon-guide-agents-addons-question", text: I18n.t("guide.options.question_type.choices"))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
    end
  end
end
