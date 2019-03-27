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

  context "required text field" do
    let!(:form) { create :gws_survey_form, cur_site: site, readable_setting_range: "public", readable_group_ids: [], readable_member_ids: [], state: "public" }
    let!(:column1) { create :gws_column_text_field, cur_site: site, form: form, order: 10, required: "required", input_type: "text" }

    context "without any answers" do
      it do
        login_gws_user

        visit gws_survey_main_path(site: site)
        click_on form.name
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#errorExplanation', text: I18n.t("errors.messages.blank"))
        expect(Gws::Survey::File.count).to eq 0
      end
    end

    context "with answer" do
      it do
        login_gws_user

        visit gws_survey_main_path(site: site)
        click_on form.name
        within "form#item-form" do
          fill_in "custom[#{column1.id}]", with: unique_id
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        expect(Gws::Survey::File.all).to have(1).items
        Gws::Survey::File.all.first.tap do |answer|
          expect(answer.form_id).to eq form.id
          expect(answer.user_id).to eq gws_user.id
          expect(answer.name).to include(form.name)
          expect(answer.anonymous_state).to eq form.anonymous_state
          expect(answer.column_values).to have(1).items
          answer.column_values.first.tap do |column_value|
            expect(column_value).to be_a(Gws::Column::Value::TextField)
            expect(column_value.name).to eq column1.name
            expect(column_value.order).to eq column1.order
            expect(column_value.order).to eq column1.order
            expect(column_value.value).to be_present
          end
        end
      end
    end
  end
end
