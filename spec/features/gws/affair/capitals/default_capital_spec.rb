require 'spec_helper'

describe "gws_affair_capitals", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  let!(:group1) { create :gws_group, name: "#{site.name}/group1" }
  let!(:group2) { create :gws_group, name: "#{site.name}/group2" }
  let!(:group3) { create :gws_group, name: "#{site.name}/group3" }

  let!(:user1) { create :gws_user, group_ids: [group1.id], gws_role_ids: gws_user.gws_role_ids }
  let!(:user2) { create :gws_user, group_ids: [group2.id], gws_role_ids: gws_user.gws_role_ids }
  let!(:user3) { create :gws_user, group_ids: [group3.id], gws_role_ids: gws_user.gws_role_ids }

  let!(:year1) do
    create(:gws_affair_capital_year,
      name: "R2",
      code: 2020,
      start_date: Time.zone.parse("2020/4/1"),
      close_date: Time.zone.parse("2021/3/31")
    )
  end
  let!(:year2) do
    create(:gws_affair_capital_year,
      name: "R3",
      code: 2021,
      start_date: Time.zone.parse("2021/4/1"),
      close_date: Time.zone.parse("2022/3/31")
    )
  end
  let!(:item1) do
    create(:gws_affair_capital, article_code: 1_111, year: year1, member_ids: [user1.id], member_group_ids: [group1.id])
  end
  let!(:item2) do
    create(:gws_affair_capital, article_code: 2_222, year: year1, member_group_ids: [group1.id, group2.id])
  end
  let!(:item3) do
    create(:gws_affair_capital, article_code: 3_333, year: year2, member_ids: [user3.id])
  end

  let(:new_path) { new_gws_affair_overtime_file_path site.id, "mine" }

  context "login with user1" do
    it do
      Timecop.freeze(year1.start_date) do
        login_user user1
        visit new_path

        name = item1.name
        target = user1.name
        expect(page).to have_css('.selected-capital', text: I18n.t("gws/affair.views.capital_title", name: name, target: target))
      end
    end

    it do
      Timecop.freeze(year2.start_date) do
        login_user user1
        visit new_path

        name = I18n.t("gws/affair.views.not_set_capital")
        target = user1.name
        expect(page).to have_css('.selected-capital', text: I18n.t("gws/affair.views.capital_title", name: name, target: target))
      end
    end
  end

  context "login with user2" do
    it do
      Timecop.freeze(year1.start_date) do
        login_user user2
        visit new_path

        name = item2.name
        target = user2.name
        expect(page).to have_css('.selected-capital', text: I18n.t("gws/affair.views.capital_title", name: name, target: target))
      end
    end

    it do
      Timecop.freeze(year2.start_date) do
        login_user user2
        visit new_path

        name = I18n.t("gws/affair.views.not_set_capital")
        target = user2.name
        expect(page).to have_css('.selected-capital', text: I18n.t("gws/affair.views.capital_title", name: name, target: target))
      end
    end
  end

  context "login with user3" do
    it do
      Timecop.freeze(year1.start_date) do
        login_user user3
        visit new_path

        name = I18n.t("gws/affair.views.not_set_capital")
        target = user3.name
        expect(page).to have_css('.selected-capital', text: I18n.t("gws/affair.views.capital_title", name: name, target: target))
      end
    end

    it do
      Timecop.freeze(year2.close_date) do
        login_user user3
        visit new_path

        name = item3.name
        target = user3.name
        expect(page).to have_css('.selected-capital', text: I18n.t("gws/affair.views.capital_title", name: name, target: target))
      end
    end
  end
end
