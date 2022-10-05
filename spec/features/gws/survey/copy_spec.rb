require 'spec_helper'

describe "gws_survey copy", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  context "copy" do
    let(:form_name) { "form-#{unique_id}" }
    let(:column_name) { "column-#{unique_id}" }
    let(:column_options) { [ "option-#{unique_id}", "option-#{unique_id}", "option-#{unique_id}" ] }
    let(:copy_name) { "copy-#{unique_id}" }

    it do
      login_gws_user

      # create new form
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: form_name
        choose I18n.t("gws.options.readable_setting_range.public")
        click_on I18n.t("gws.apis.categories.index")
      end
      wait_for_cbox do
        expect(page).to have_content(cate.name)
        click_on cate.name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Survey::Form.all.count).to eq 1

      click_on(I18n.t('gws/workflow.columns.index'))

      within ".nav-menu" do
        click_on(I18n.t("ss.links.new"))
      end
      within ".gws-dropdown-menu" do
        click_on(I18n.t("gws.columns.gws/radio_button"))
      end
      within "form#item-form" do
        fill_in "item[name]", with: column_name
        fill_in "item[select_options]", with: column_options.join("\n")
        click_on(I18n.t("ss.buttons.save"))
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      # publish
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name
      click_on I18n.t("gws/workflow.links.publish")

      within "form" do
        click_on(I18n.t("ss.buttons.save"))
      end

      expect(Gws::Survey::Form.all.count).to eq 1

      # answer by user1
      login_user user1
      visit gws_survey_main_path(site: site)
      click_on form_name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options[0]
        end
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      # copy
      login_gws_user
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name
      click_on I18n.t("ss.links.copy")

      within "form#item-form" do
        fill_in "copy[name]", with: copy_name
        select I18n.t("ss.options.state.enabled"), from: 'copy[anonymous_state]'
        select I18n.t("ss.options.state.public"), from: 'copy[file_state]'
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.copied"))

      copy_form = Gws::Survey::Form.where(name: copy_name).first
      expect(copy_form.state).to eq "closed"
      expect(copy_form.columns.count).to eq 1

      # publish
      click_on copy_name
      click_on I18n.t("gws/workflow.links.publish")

      within "form" do
        click_on(I18n.t("ss.buttons.save"))
      end

      expect(Gws::Survey::Form.all.count).to eq 2

      # answer by user2
      login_user user2
      visit gws_survey_main_path(site: site)

      click_on copy_name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options[1]
        end
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      # check answers
      form = Gws::Survey::Form.where(name: form_name).first
      answers = form.files.to_a
      answer = answers.first

      expect(answers.count).to eq 1
      expect(answer.user_name).to eq user1.name
      expect(answer.column_values.count).to eq 1
      expect(answer.column_values.first.value).to eq column_options[0]

      copy_form = Gws::Survey::Form.where(name: copy_name).first
      answers = copy_form.files.to_a
      answer = answers.first

      expect(answers.count).to eq 1
      expect(answer.user_name).to eq user2.name
      expect(answer.column_values.count).to eq 1
      expect(answer.column_values.first.value).to eq column_options[1]
    end
  end
end
