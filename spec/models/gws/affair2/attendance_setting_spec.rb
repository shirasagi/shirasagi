require 'spec_helper'

describe Gws::Affair2::AttendanceSetting, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:user1) { create :gws_user, group_ids: user.group_ids, organization_id: site.id, organization_uid: "0001" }
  let!(:user2) { create :gws_user, group_ids: user.group_ids, organization_id: site.id, organization_uid: "9901" }

  let!(:special_leave1) { create :gws_affair2_special_leave }
  let!(:special_leave2) { create :gws_affair2_special_leave }
  let!(:special_leave3) { create :gws_affair2_special_leave }
  let!(:leave_setting) do
    create(:gws_affair2_leave_setting, special_leave_ids: [special_leave1.id, special_leave2.id, special_leave3.id])
  end
  let!(:duty_setting) { create :gws_affair2_duty_setting }

  context "#validate_double_booking" do
    let(:user1_attr) do
      {
        cur_site: site,
        cur_user: user1,
        organization_uid: user1.uid,
        duty_setting: duty_setting,
        leave_setting: leave_setting
      }
    end
    let(:user2_attr) do
      {
        cur_site: site,
        cur_user: user2,
        organization_uid: user2.uid,
        duty_setting: duty_setting,
        leave_setting: leave_setting
      }
    end
    let(:messages) { ["開始~終了が重複している設定が存在します。"] }

    it do
      # user1
      ## OK. 2024/1/1 - 2024/2/29
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 1
      item.in_close_year = 2024
      item.in_close_month = 2
      expect(item).to be_valid
      item.save!

      ## OK. 2024/3/1 - 2024/6/30
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 3
      item.in_close_year = 2024
      item.in_close_month = 6
      expect(item).to be_valid
      item.save!

      ## NG. 2024/5/1 - 2024/6/30
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 5
      item.in_close_year = 2024
      item.in_close_month = 6
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # NG. 2024/2/1 - 2024/3/31
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 2
      item.in_close_year = 2024
      item.in_close_month = 3
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # NG. 2023/11/1 - 2024/2/29
      item = described_class.new user1_attr
      item.in_start_year = 2023
      item.in_start_month = 11
      item.in_close_year = 2024
      item.in_close_month = 2
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # NG. 2023/11/1 - 2024/2/29
      item = described_class.new user1_attr
      item.in_start_year = 2023
      item.in_start_month = 11
      item.in_close_year = 2024
      item.in_close_month = 2
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # NG. 2023/1/1 -
      item = described_class.new user1_attr
      item.in_start_year = 2023
      item.in_start_month = 1
      item.in_close_year = nil
      item.in_close_month = nil
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # NG. 2024/6/1 -
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 6
      item.in_close_year = nil
      item.in_close_month = nil
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # OK. 2024/7/1 -
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 7
      item.in_close_year = nil
      item.in_close_month = nil
      expect(item).to be_valid
      item.save!

      # NG. 2024/8/1 - 2024/9/30
      item = described_class.new user1_attr
      item.in_start_year = 2024
      item.in_start_month = 8
      item.in_close_year = 2024
      item.in_close_month = 9
      expect(item).to be_invalid
      expect(item.errors.full_messages).to eq messages

      # user2
      ## OK. 2023/1/1 -
      item = described_class.new user2_attr
      item.in_start_year = 2023
      item.in_start_month = 1
      item.in_close_year = nil
      item.in_close_month = nil
      expect(item).to be_valid
      item.save!
    end
  end
end
