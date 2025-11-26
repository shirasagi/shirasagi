require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20251126000000_organization_uid_numeric.rb")

RSpec.describe SS::Migration20251126000000, dbscope: :example do
  let(:site) { gws_site }
  let(:organization) { create :ss_group }

  describe "#change" do
    context "with users having organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: "5880" }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "10081" }
      let!(:user3) { create :gws_user, organization_id: organization.id, organization_uid: "0" }
      let!(:user4) { create :gws_user, organization_id: organization.id, organization_uid: "9999" }

      before do
        # マイグレーション実行前にorganization_uid_numericをクリア（既存データをシミュレート）
        user1.without_record_timestamps { user1.set(organization_uid_numeric: nil) }
        user2.without_record_timestamps { user2.set(organization_uid_numeric: nil) }
        user3.without_record_timestamps { user3.set(organization_uid_numeric: nil) }
        user4.without_record_timestamps { user4.set(organization_uid_numeric: nil) }

        # マイグレーション実行前にorganization_uid_numericがnilであることを確認
        expect(user1.reload.organization_uid_numeric).to be_nil
        expect(user2.reload.organization_uid_numeric).to be_nil
        expect(user3.reload.organization_uid_numeric).to be_nil
        expect(user4.reload.organization_uid_numeric).to be_nil

        described_class.new.change
      end

      it "sets organization_uid_numeric correctly" do
        expect(user1.reload.organization_uid_numeric).to eq 5880
        expect(user2.reload.organization_uid_numeric).to eq 10_081
        expect(user3.reload.organization_uid_numeric).to eq 0
        expect(user4.reload.organization_uid_numeric).to eq 9999
      end
    end

    context "with users without organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: nil }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "" }

      before do
        described_class.new.change
      end

      it "does not set organization_uid_numeric for users without organization_uid" do
        expect(user1.reload.organization_uid_numeric).to be_nil
        expect(user2.reload.organization_uid_numeric).to be_nil
      end
    end

    context "with users having non-numeric organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: "abc" }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "xyz123" }

      before do
        # マイグレーション実行前にorganization_uid_numericをクリア（既存データをシミュレート）
        user1.without_record_timestamps { user1.set(organization_uid_numeric: nil) }
        user2.without_record_timestamps { user2.set(organization_uid_numeric: nil) }

        described_class.new.change
      end

      it "skips users with non-numeric organization_uid (converts to 0 but not '0')" do
        # "abc"や"xyz123"は数値に変換すると0になるが、"0"ではないためスキップされる
        expect(user1.reload.organization_uid_numeric).to be_nil
        expect(user2.reload.organization_uid_numeric).to be_nil
      end
    end

    context "with users having already set organization_uid_numeric" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: "100" }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "200" }

      before do
        # 既にorganization_uid_numericが設定されている場合
        user1.set(organization_uid_numeric: 999)
        user2.set(organization_uid_numeric: 888)

        described_class.new.change
      end

      it "overwrites existing organization_uid_numeric with correct value" do
        expect(user1.reload.organization_uid_numeric).to eq 100
        expect(user2.reload.organization_uid_numeric).to eq 200
      end
    end

    context "with large number of users" do
      before do
        # 25人のユーザーを作成（バッチ処理をテストするため）
        25.times do |i|
          create :gws_user, organization_id: organization.id, organization_uid: (1000 + i).to_s
        end
      end

      it "processes all users in batches" do
        expect { described_class.new.change }.not_to raise_error

        SS::User.unscoped.where(organization_id: organization.id).each do |user|
          expect(user.organization_uid_numeric).to eq user.organization_uid.to_i
        end
      end
    end
  end
end
