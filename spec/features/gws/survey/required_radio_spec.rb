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

  context "required radio without other option" do
    let!(:form) do
      create(
        :gws_survey_form, cur_site: site, state: "public",
        readable_setting_range: "public", readable_group_ids: [], readable_member_ids: []
      )
    end
    let!(:column1) { create :gws_column_radio_button, cur_site: site, form: form, order: 10, required: "required" }

    context "without any answers" do
      it do
        login_gws_user

        visit gws_survey_main_path(site: site)
        click_on form.name
        within "form#item-form" do
          click_on I18n.t("ss.buttons.answer")
        end
        expect(page).to have_css('#errorExplanation', text: I18n.t("errors.messages.blank"))
        expect(Gws::Survey::File.count).to eq 0
      end
    end

    context "with answer" do
      let(:answer_value) { column1.select_options.sample }

      it do
        login_gws_user

        visit gws_survey_main_path(site: site)
        click_on form.name
        within "form#item-form" do
          find("input[value='#{answer_value}']").set(true)
          click_on I18n.t("ss.buttons.answer")
        end
        wait_for_notice I18n.t('ss.notice.answered')

        expect(Gws::Survey::File.all).to have(1).items
        Gws::Survey::File.all.first.tap do |answer|
          expect(answer.form_id).to eq form.id
          expect(answer.user_id).to eq gws_user.id
          expect(answer.name).to include(form.name)
          expect(answer.anonymous_state).to eq form.anonymous_state
          expect(answer.column_values).to have(1).items
          answer.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Gws::Column::Value::RadioButton)
            expect(column_value.name).to eq column1.name
            expect(column_value.order).to eq column1.order
            expect(column_value.value).to eq answer_value
            expect(column_value.other_value).to be_blank
          end
        end
      end
    end
  end

  context "required radio with required others" do
    let!(:form) do
      create(
        :gws_survey_form, cur_site: site, state: "public",
        readable_setting_range: "public", readable_group_ids: [], readable_member_ids: []
      )
    end
    let!(:column1) do
      create(
        :gws_column_radio_button, cur_site: site, form: form, order: 10, required: "required",
        other_state: "enabled", other_required: "required")
    end

    context "when answering with one of select_options" do
      let(:answer_value) { column1.select_options.sample }

      it do
        login_gws_user

        visit gws_survey_main_path(site: site)
        click_on form.name
        within "form#item-form" do
          find("input[value='#{answer_value}']").set(true)
          click_on I18n.t("ss.buttons.answer")
        end
        wait_for_notice I18n.t('ss.notice.answered')

        expect(Gws::Survey::File.all).to have(1).items
        Gws::Survey::File.all.first.tap do |answer|
          expect(answer.form_id).to eq form.id
          expect(answer.user_id).to eq gws_user.id
          expect(answer.name).to include(form.name)
          expect(answer.anonymous_state).to eq form.anonymous_state
          expect(answer.column_values).to have(1).items
          answer.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Gws::Column::Value::RadioButton)
            expect(column_value.name).to eq column1.name
            expect(column_value.order).to eq column1.order
            expect(column_value.value).to eq answer_value
            expect(column_value.other_value).to be_blank
          end
        end
      end
    end

    context "when answering with other" do
      let(:other_value) { "other-#{unique_id}" }

      it do
        login_gws_user

        visit gws_survey_main_path(site: site)
        click_on form.name
        within "form#item-form" do
          find("input[data-section-id='other']").set(true)
          fill_in "custom[#{column1.id}_other_value]", with: other_value

          click_on I18n.t("ss.buttons.answer")
        end
        wait_for_notice I18n.t('ss.notice.answered')

        expect(Gws::Survey::File.all).to have(1).items
        Gws::Survey::File.all.first.tap do |answer|
          expect(answer.form_id).to eq form.id
          expect(answer.user_id).to eq gws_user.id
          expect(answer.name).to include(form.name)
          expect(answer.anonymous_state).to eq form.anonymous_state
          expect(answer.column_values).to have(1).items
          answer.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Gws::Column::Value::RadioButton)
            expect(column_value.name).to eq column1.name
            expect(column_value.order).to eq column1.order
            expect(column_value.value).to eq "$other_value$"
            expect(column_value.other_value).to eq other_value
          end
        end
      end
    end
  end
end
