require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20260324000000_organization_uid_sort_key.rb")

RSpec.describe SS::Migration20260324000000, dbscope: :example do
  let(:site) { gws_site }
  let(:organization) { create :ss_group }

  describe "#change" do
    context "with users having numeric organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: "5880" }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "10081" }
      let!(:user3) { create :gws_user, organization_id: organization.id, organization_uid: "0" }

      before do
        # マイグレーション実行前にソートフィールドをクリア（既存データをシミュレート）
        [user1, user2, user3].each do |user|
          user.without_record_timestamps do
            user.set(organization_uid_type: nil, organization_uid_sort_key: nil)
          end
        end

        described_class.new.change
      end

      it "sets organization_uid_type and organization_uid_sort_key correctly" do
        expect(user1.reload.organization_uid_type).to eq 'numeric'
        expect(user1.organization_uid_sort_key).to eq '0000005880'

        expect(user2.reload.organization_uid_type).to eq 'numeric'
        expect(user2.organization_uid_sort_key).to eq '0000010081'

        expect(user3.reload.organization_uid_type).to eq 'numeric'
        expect(user3.organization_uid_sort_key).to eq '0000000000'
      end
    end

    context "with users having alphanumeric organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: "A1234" }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "KB005" }
      let!(:user3) { create :gws_user, organization_id: organization.id, organization_uid: "abc" }

      before do
        [user1, user2, user3].each do |user|
          user.without_record_timestamps do
            user.set(organization_uid_type: nil, organization_uid_sort_key: nil)
          end
        end

        described_class.new.change
      end

      it "sets organization_uid_type to alpha and generates correct sort key" do
        expect(user1.reload.organization_uid_type).to eq 'alpha'
        expect(user1.organization_uid_sort_key).to eq 'A0000001234'

        expect(user2.reload.organization_uid_type).to eq 'alpha'
        expect(user2.organization_uid_sort_key).to eq 'KB0000000005'

        expect(user3.reload.organization_uid_type).to eq 'alpha'
        expect(user3.organization_uid_sort_key).to eq 'abc'
      end
    end

    context "with users having special characters in organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: "user_001" }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "user-002" }

      before do
        [user1, user2].each do |user|
          user.without_record_timestamps do
            user.set(organization_uid_type: nil, organization_uid_sort_key: nil)
          end
        end

        described_class.new.change
      end

      it "preserves underscores and hyphens in sort key" do
        expect(user1.reload.organization_uid_type).to eq 'alpha'
        expect(user1.organization_uid_sort_key).to eq 'user_0000000001'

        expect(user2.reload.organization_uid_type).to eq 'alpha'
        expect(user2.organization_uid_sort_key).to eq 'user-0000000002'
      end
    end

    context "with users without organization_uid" do
      let!(:user1) { create :gws_user, organization_id: organization.id, organization_uid: nil }
      let!(:user2) { create :gws_user, organization_id: organization.id, organization_uid: "" }

      before do
        described_class.new.change
      end

      it "sets both fields to nil for users without organization_uid" do
        expect(user1.reload.organization_uid_type).to be_nil
        expect(user1.organization_uid_sort_key).to be_nil

        expect(user2.reload.organization_uid_type).to be_nil
        expect(user2.organization_uid_sort_key).to be_nil
      end
    end

    context "with large number of users" do
      before do
        25.times do |i|
          create :gws_user, organization_id: organization.id, organization_uid: (1000 + i).to_s
        end
      end

      it "processes all users in batches" do
        expect { described_class.new.change }.not_to raise_error

        SS::User.unscoped.where(organization_id: organization.id).each do |user|
          expect(user.organization_uid_type).to eq 'numeric'
          expect(user.organization_uid_sort_key).to be_present
        end
      end
    end
  end
end
