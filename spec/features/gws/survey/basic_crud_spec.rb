require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  before do
    site.canonical_scheme = 'http'
    site.canonical_domain = 'www.example.jp'
    site.save!
  end

  context "basic crud" do
    let(:form_name) { "form-#{unique_id}" }
    let(:column_name) { "column-#{unique_id}" }
    let(:column_options) { [ "option-#{unique_id}", "option-#{unique_id}", "option-#{unique_id}" ] }

    it do
      login_gws_user

      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on I18n.t("ss.links.new")

      within "form#item-form" do
        fill_in "item[name]", with: form_name
        choose I18n.t("gws.options.readable_setting_range.public")
        click_on I18n.t("gws.apis.categories.index")
      end
      within "#cboxLoadedContent" do
        expect(page).to have_content(cate.name)
        click_on cate.name
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      expect(Gws::Survey::Form.all.count).to eq 1

      click_on(I18n.t('gws/workflow.columns.index'))

      click_on(I18n.t("ss.links.new"))
      click_on(I18n.t("mongoid.models.gws/column/radio_button"))
      within "form#item-form" do
        fill_in "item[name]", with: column_name
        fill_in "item[select_options]", with: column_options.join("\n")
        click_on(I18n.t("ss.buttons.save"))
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name
      click_on I18n.t("gws/workflow.links.publish")

      within "form" do
        click_on(I18n.t("ss.buttons.save"))
      end

      expect(Gws::Survey::Form.all.count).to eq 1
      form = Gws::Survey::Form.all.site(site).find_by(name: form_name)

      expect(Gws::Memo::Notice.all.count).to eq 1
      Gws::Memo::Notice.all.first.tap do |notice|
        subject = I18n.t("gws_notification.#{Gws::Survey::Form.model_name.i18n_key}.subject", name: form.name, default: form.name)
        expect(notice.subject).to eq subject
        expect(notice.member_ids).to include(user1.id, user2.id)
      end

      #
      # answer by user1
      #
      login_user user1
      visit gws_survey_main_path(site: site)
      click_on form_name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options.sample
        end
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      #
      # answer by user2
      #
      login_user user2
      visit gws_survey_main_path(site: site)
      click_on form_name
      within "form#item-form" do
        within ".mod-gws-survey-custom_form" do
          choose column_options.sample
        end
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))

      #
      # check answers
      #
      login_gws_user
      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on form_name

      click_on I18n.t("gws/survey.view_files")

      expect(page).to have_text(user1.name)
      expect(page).to have_text(user2.name)

      click_on I18n.t("gws/survey.tabs.summary")
    end
  end
end
