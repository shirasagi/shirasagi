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

  context "public file state" do
    let!(:form) do
      create(
        :gws_survey_form, cur_site: site, readable_setting_range: "public", readable_group_ids: [], readable_member_ids: [],
        state: "public", file_state: "public"
      )
    end
    let!(:column1) do
      create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "required", input_type: "text")
    end
    let(:user1_answer) { unique_id }
    let(:user2_answer) { unique_id }

    it do
      #
      # user1
      #
      login_user user1

      visit gws_survey_main_path(site: site)
      click_on form.name
      expect(page).to have_css(".gws-survey .limit", text: Gws::Survey::Form.t(:due_date))
      within "form#item-form" do
        fill_in "custom[#{column1.id}]", with: user1_answer
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      #
      #  user2
      #
      login_user user2

      visit gws_survey_main_path(site: site)
      click_on form.name
      within "form#item-form" do
        fill_in "custom[#{column1.id}]", with: user2_answer
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      click_on form.name
      click_on I18n.t("gws/survey.tabs.others")
      expect(page).to have_css(".gws-survey .answered", text: Gws::Survey::File.t(:updated))
      expect(page).to have_css(".gws-survey .form-table-body", text: user1_answer)
    end
  end
end
