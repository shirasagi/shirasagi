require 'spec_helper'

describe "gws_affair_capitals", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  let!(:group1) { create :gws_group, name: "#{site.name}/group1", group_code: 110000 }
  let!(:group2) { create :gws_group, name: "#{site.name}/group2", group_code: 110001 }
  let!(:group3) { create :gws_group, name: "#{site.name}/group3", group_code: 110002 }

  let!(:user1) do
    create(:gws_user,
      name: "user1",
      group_ids: [group1.id],
      staff_address_uid: 11111
    )
  end
  let!(:user2) do
    create(:gws_user,
      name: "user2",
      group_ids: [group2.id],
      staff_address_uid: 11112
    )
  end
  let!(:user3) do
    create(:gws_user,
      name: "user3",
      group_ids: [group3.id],
      staff_address_uid: 11113
    )
  end

  let!(:year1) do
    create(:gws_affair_capital_year,
      name: "令和2年",
      code: 2020,
      start_date: Time.zone.parse("2020/4/1"),
      close_date: Time.zone.parse("2021/3/31"),
    )
  end
  let!(:year2) do
    create(:gws_affair_capital_year,
      name: "令和3年",
      code: 2021,
      start_date: Time.zone.parse("2021/4/1"),
      close_date: Time.zone.parse("2022/3/31"),
    )
  end

  let(:index_path) { gws_affair_capitals_path site.id, year1.id }
  let(:import_path) { import_gws_affair_capitals_path site.id, year1.id }
  let(:import_member_path) { import_member_gws_affair_capitals_path site.id, year1.id }
  let(:import_group_path) { import_group_gws_affair_capitals_path site.id, year1.id }

  def find_capital(year, project_code, detail_code)
    year.yearly_capitals.find_by(project_code: project_code, detail_code: detail_code)
  end

  context "import capitals" do
    before { login_gws_user }

    it do
      # import capitals
      visit import_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/capitals.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end

      expect(current_path).to eq index_path
      expect(page).to have_content I18n.t("ss.notice.saved")

      year1.reload
      year2.reload

      expect(year1.yearly_capitals.count).to eq 97
      expect(year2.yearly_capitals.count).to eq 0

      # import members 1
      visit import_member_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/capital_members1.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end

      expect(current_path).to eq import_member_path
      expect(page).to have_content I18n.t("ss.notice.saved")

      year1.reload
      year2.reload

      expect(year1.yearly_capitals.pluck(:member_ids).select(&:present?).count).to eq 3
      expect(year1.yearly_capitals.pluck(:member_group_ids).select(&:present?).count).to eq 0
      expect(find_capital(year1, 1, 17).member_ids).to match_array [user1.id]
      expect(find_capital(year1, 693,78).member_ids).to match_array [user2.id]
      expect(find_capital(year1, 2596,23134).member_ids).to match_array [user3.id]
      expect(find_capital(year1, 20, 19034).member_ids).to match_array []
      expect(find_capital(year1, 21,19164).member_ids).to match_array []

      # import members 2
      visit import_member_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/capital_members2.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end

      expect(current_path).to eq import_member_path
      expect(page).to have_content I18n.t("ss.notice.saved")

      year1.reload
      year2.reload

      expect(year1.yearly_capitals.pluck(:member_ids).select(&:present?).count).to eq 3
      expect(year1.yearly_capitals.pluck(:member_group_ids).select(&:present?).count).to eq 0
      expect(find_capital(year1, 1, 17).member_ids).to match_array [user1.id]
      expect(find_capital(year1, 693,78).member_ids).to match_array []
      expect(find_capital(year1, 2596,23134).member_ids).to match_array []
      expect(find_capital(year1, 20, 19034).member_ids).to match_array [user2.id]
      expect(find_capital(year1, 21,19164).member_ids).to match_array [user3.id]

      # import group 1
      visit import_group_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/capital_groups1.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end

      expect(current_path).to eq import_group_path
      expect(page).to have_content I18n.t("ss.notice.saved")

      year1.reload
      year2.reload

      expect(year1.yearly_capitals.pluck(:member_ids).select(&:present?).count).to eq 3
      expect(year1.yearly_capitals.pluck(:member_group_ids).select(&:present?).count).to eq 3
      expect(find_capital(year1, 1, 17).member_group_ids).to match_array [group1.id]
      expect(find_capital(year1, 1441, 12269).member_group_ids).to match_array [group2.id]
      expect(find_capital(year1, 1812,17994).member_group_ids).to match_array [group3.id]
      expect(find_capital(year1, 2627,23533).member_group_ids).to match_array []
      expect(find_capital(year1, 1014,7502).member_group_ids).to match_array []

      # import group 2
      visit import_group_path
      within "form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/capital_groups2.csv"
        page.accept_confirm do
          click_on I18n.t("ss.links.import")
        end
      end

      expect(current_path).to eq import_group_path
      expect(page).to have_content I18n.t("ss.notice.saved")

      year1.reload
      year2.reload

      expect(year1.yearly_capitals.pluck(:member_ids).select(&:present?).count).to eq 3
      expect(year1.yearly_capitals.pluck(:member_group_ids).select(&:present?).count).to eq 3
      expect(find_capital(year1, 1, 17).member_group_ids).to match_array [group1.id]
      expect(find_capital(year1, 1441, 12269).member_group_ids).to match_array []
      expect(find_capital(year1, 1812,17994).member_group_ids).to match_array []
      expect(find_capital(year1, 2627,23533).member_group_ids).to match_array [group2.id]
      expect(find_capital(year1, 1014,7502).member_group_ids).to match_array [group3.id]
    end
  end
end
