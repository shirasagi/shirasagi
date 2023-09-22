require 'spec_helper'

describe "gws_affair_leave_settings", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { gws_site }
    let!(:group1) { create :gws_group, name: "#{site.name}/group1" }
    let!(:group2) { create :gws_group, name: "#{site.name}/group2" }
    let!(:group3) { create :gws_group, name: "#{site.name}/group3" }

    let!(:user1) do
      create(:gws_user,
        name: "user1",
        group_ids: [group1.id],
        staff_address_uid: "11111"
      )
    end
    let!(:user2) do
      create(:gws_user,
        name: "user2",
        group_ids: [group2.id],
        staff_address_uid: "11112"
      )
    end
    let!(:user3) do
      create(:gws_user,
        name: "user3",
        group_ids: [group3.id],
        staff_address_uid: "11113"
      )
    end

    let!(:year1) do
      create(:gws_affair_capital_year,
        name: "令和2年",
        code: 2020,
        start_date: Time.zone.parse("2020/4/1"),
        close_date: Time.zone.parse("2021/3/31")
      )
    end
    let!(:year2) do
      create(:gws_affair_capital_year,
        name: "令和3年",
        code: 2021,
        start_date: Time.zone.parse("2021/4/1"),
        close_date: Time.zone.parse("2022/3/31")
      )
    end

    let(:index_path) { gws_affair_leave_settings_path site.id, year1.id }
    let(:import_path) { import_gws_affair_leave_settings_path site.id, year1.id }
    let(:import_member_path) { import_member_gws_affair_leave_settings_path site.id, year1.id }

    def find_leave_setting(year, staff_address_uid)
      target_user = Gws::User.find_by(staff_address_uid: staff_address_uid)
      year.yearly_leave_settings.find_by(target_user_id: target_user.id)
    end

    context "import leave_settings" do
      before { login_gws_user }

      it do
        # import leave_settings_member
        visit import_member_path
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/leave_settings_member.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(current_path).to eq import_member_path

        year1.reload
        year2.reload

        expect(find_leave_setting(year1, "162167").count).to eq 110
        expect(find_leave_setting(year1, "32018").count).to eq 111
        expect(find_leave_setting(year1, "1289012").count).to eq 112
        expect(find_leave_setting(year1, "1609661").count).to eq 138
        expect(find_leave_setting(year1, "1730169").count).to eq 139
        expect(find_leave_setting(year1, "836001").count).to eq 140
      end

      it do
        # import leave_settings
        visit import_path
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/leave_settings.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(current_path).to eq index_path

        year1.reload
        year2.reload

        expect(year1.yearly_leave_settings.count).to eq 31
        expect(year2.yearly_leave_settings.count).to eq 0

        expect(find_leave_setting(year1, "162167").count).to eq 10
        expect(find_leave_setting(year1, "32018").count).to eq 11
        expect(find_leave_setting(year1, "1289012").count).to eq 12
        expect(find_leave_setting(year1, "1609661").count).to eq 38
        expect(find_leave_setting(year1, "1730169").count).to eq 39
        expect(find_leave_setting(year1, "836001").count).to eq 40

        # import leave_settings_member
        visit import_member_path
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/leave_settings_member.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(current_path).to eq import_member_path

        year1.reload
        year2.reload

        expect(find_leave_setting(year1, "162167").count).to eq 110
        expect(find_leave_setting(year1, "32018").count).to eq 111
        expect(find_leave_setting(year1, "1289012").count).to eq 112
        expect(find_leave_setting(year1, "1609661").count).to eq 138
        expect(find_leave_setting(year1, "1730169").count).to eq 139
        expect(find_leave_setting(year1, "836001").count).to eq 140

        # import leave_settings2
        visit import_path
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/gws/affair/leave_settings2.csv"
          page.accept_confirm do
            click_on I18n.t("ss.links.import")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(current_path).to eq index_path

        year1.reload
        year2.reload

        expect(year1.yearly_leave_settings.count).to eq 31
        expect(year2.yearly_leave_settings.count).to eq 0

        expect(find_leave_setting(year1, "162167").count).to eq 10
        expect(find_leave_setting(year1, "32018").count).to eq 11
        expect(find_leave_setting(year1, "1289012").count).to eq 12
        expect(find_leave_setting(year1, "1609661").count).to eq 38
        expect(find_leave_setting(year1, "1730169").count).to eq 39
        expect(find_leave_setting(year1, "836001").count).to eq 40
      end
    end
  end
end
