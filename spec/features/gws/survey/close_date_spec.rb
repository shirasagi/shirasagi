require 'spec_helper'

describe "gws_survey", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) do
    create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids)
  end
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  context "with closed public form" do
    let!(:item1) do
      Timecop.freeze(now - 1.week) do
        create(
          :gws_survey_form, state: "public", close_date: now - 1.day, due_date: now - 2.days,
          readable_setting_range: "select", readable_member_ids: [user1.id])
      end
    end

    it do
      login_gws_user

      visit gws_survey_main_path(site: site)
      click_on I18n.t("ss.navi.editable")
      click_on item1.name
      within ".nav-menu" do
        expect(page).to have_link(I18n.t('gws/workflow.links.depublish'))
        expect(page).to have_no_link(I18n.t('gws/workflow.links.publish'))
        expect(page).to have_no_link(I18n.t('ss.links.edit'))

        click_on I18n.t('gws/workflow.links.depublish')
      end

      within "form#item-form" do
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.depublished")

      Gws::Survey::Form.find(item1.id).tap do |item|
        expect(item.state).to eq "closed"
        expect(item.close_date).to eq now - 1.day
        expect(item.due_date).to eq now - 2.days
      end
    end
  end
end
