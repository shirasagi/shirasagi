require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:form) do
    create(
      :gws_survey_form, cur_site: site, state: "closed",
      readable_setting_range: "select", readable_custom_group_ids: [], readable_group_ids: [],
      readable_member_ids: [ user1.id ],
      custom_group_ids: [], group_ids: [], user_ids: [ user1.id, user2.id ]
    )
  end
  let!(:column1) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "required", input_type: "text")
  end

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = unique_domain
    site.save!
  end

  context "preview" do
    context "with user who is a manger and reader" do
      it do
        login_user user1

        visit gws_survey_main_path(site: site)
        within ".current-navi" do
          click_on I18n.t("ss.navi.editable")
        end
        click_on form.name

        within "#addon-gws-agents-addons-survey-column_setting" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.links.preview")
          end
        end

        within_cbox do
          expect(page).to have_css(".mod-gws-survey-custom_form", text: column1.name)
        end
      end
    end

    context "with user who is a manger, but not a reader" do
      it do
        login_user user2

        visit gws_survey_main_path(site: site)
        within ".current-navi" do
          click_on I18n.t("ss.navi.editable")
        end
        click_on form.name

        within "#addon-gws-agents-addons-survey-column_setting" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.links.preview")
          end
        end

        within_cbox do
          expect(page).to have_css(".mod-gws-survey-custom_form", text: column1.name)
        end
      end
    end
  end
end
