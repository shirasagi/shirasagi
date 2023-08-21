require 'spec_helper'

describe SS::Notification, dbscope: :example do
  let(:group) { ss_group }
  let(:user1) { SS::User.create(name: unique_id, uid: unique_id, in_password: "pass", group_ids: [group.id]) }
  let(:user2) { SS::User.create(name: unique_id, uid: unique_id, in_password: "pass", group_ids: [group.id]) }
  let(:user3) { SS::User.create(name: unique_id, uid: unique_id, in_password: "pass", group_ids: [group.id]) }

  describe "#user_setting" do
    let!(:notification) { create :ss_notification, member_ids: [ user1.id, user2.id, user3.id ] }

    describe "#set_seen" do
      it do
        now = Time.zone.now.beginning_of_minute
        expect(notification.unseen?(user1)).to be_truthy
        expect(notification.unseen?(user2)).to be_truthy
        expect(notification.unseen?(user3)).to be_truthy

        Timecop.freeze(now - 3.hours) do
          notification.set_seen(user2)
        end
        expect(notification.unseen?(user1)).to be_truthy
        expect(notification.unseen?(user2)).to be_falsey
        expect(notification.unseen?(user3)).to be_truthy
        notification.reload
        expect(notification.send(:find_user_setting, user2.id, "seen_at")).to eq now - 3.hours

        Timecop.freeze(now - 2.hours) do
          notification.set_seen(user1)
        end
        expect(notification.unseen?(user1)).to be_falsey
        expect(notification.unseen?(user2)).to be_falsey
        expect(notification.unseen?(user3)).to be_truthy
        notification.reload
        expect(notification.send(:find_user_setting, user1.id, "seen_at")).to eq now - 2.hours

        Timecop.freeze(now - 1.hour) do
          notification.set_seen(user3)
        end
        expect(notification.unseen?(user1)).to be_falsey
        expect(notification.unseen?(user2)).to be_falsey
        expect(notification.unseen?(user3)).to be_falsey
        notification.reload
        expect(notification.send(:find_user_setting, user3.id, "seen_at")).to eq now - 1.hour
      end
    end

    describe "#unset_seen" do
      let(:now) { Time.zone.now.beginning_of_minute }

      before do
        notification.set(user_settings: [
          { "user_id" => user1.id, "seen_at" => now.utc },
          { "user_id" => user2.id, "deleted" => now.utc },
          { "user_id" => user3.id, "seen_at" => now.utc, "deleted" => now.utc },
        ])
      end

      it do
        expect(notification.unseen?(user1)).to be_falsey
        expect(notification.deleted?(user1)).to be_falsey
        notification.unset_seen(user1)
        expect(notification.unseen?(user1)).to be_truthy
        expect(notification.deleted?(user1)).to be_falsey

        # user1's user_setting has been removed
        expect(notification.user_settings.length).to eq 2
        expect(notification.user_settings).to include({ "user_id" => user2.id, "deleted" => now.utc })
        expect(notification.user_settings).to include({ "user_id" => user3.id, "seen_at" => now.utc, "deleted" => now.utc })
      end

      it do
        expect(notification.unseen?(user2)).to be_truthy
        expect(notification.deleted?(user2)).to be_truthy
        notification.unset_seen(user2)
        expect(notification.unseen?(user2)).to be_truthy
        expect(notification.deleted?(user2)).to be_truthy

        # unchanged
        expect(notification.user_settings.length).to eq 3
        expect(notification.user_settings).to include({ "user_id" => user1.id, "seen_at" => now.utc })
        expect(notification.user_settings).to include({ "user_id" => user2.id, "deleted" => now.utc })
        expect(notification.user_settings).to include({ "user_id" => user3.id, "seen_at" => now.utc, "deleted" => now.utc })
      end

      it do
        expect(notification.unseen?(user3)).to be_falsey
        expect(notification.deleted?(user3)).to be_truthy
        notification.unset_seen(user3)
        expect(notification.unseen?(user3)).to be_truthy
        expect(notification.deleted?(user3)).to be_truthy

        # user3's seen_at has been removed
        expect(notification.user_settings.length).to eq 3
        expect(notification.user_settings).to include({ "user_id" => user1.id, "seen_at" => now.utc })
        expect(notification.user_settings).to include({ "user_id" => user2.id, "deleted" => now.utc })
        expect(notification.user_settings).to include({ "user_id" => user3.id, "deleted" => now.utc })
      end
    end

    describe "#destroy_from_member" do
      it do
        now = Time.zone.now.beginning_of_minute
        expect(notification.deleted?(user1)).to be_falsey
        expect(notification.deleted?(user2)).to be_falsey
        expect(notification.deleted?(user3)).to be_falsey

        Timecop.freeze(now - 3.hours) do
          notification.destroy_from_member(user2)
        end
        expect(notification.member_ids).to eq [user1.id, user3.id]
        expect(notification.deleted?(user1)).to be_falsey
        expect(notification.deleted?(user2)).to be_truthy
        expect(notification.deleted?(user3)).to be_falsey
        notification.reload
        expect(notification.send(:find_user_setting, user2.id, "deleted")).to eq now - 3.hours

        Timecop.freeze(now - 2.hours) do
          notification.destroy_from_member(user1)
        end
        expect(notification.member_ids).to eq [user3.id]
        expect(notification.deleted?(user1)).to be_truthy
        expect(notification.deleted?(user2)).to be_truthy
        expect(notification.deleted?(user3)).to be_falsey
        notification.reload
        expect(notification.send(:find_user_setting, user1.id, "deleted")).to eq now - 2.hours

        Timecop.freeze(now - 1.hour) do
          notification.destroy_from_member(user3)
        end
        expect { notification.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      end
    end

    describe "#set_seen and #destroy_from_member" do
      it do
        now = Time.zone.now.beginning_of_minute
        expect(notification.unseen?(user1)).to be_truthy
        expect(notification.unseen?(user2)).to be_truthy
        expect(notification.unseen?(user3)).to be_truthy
        expect(notification.deleted?(user1)).to be_falsey
        expect(notification.deleted?(user2)).to be_falsey
        expect(notification.deleted?(user3)).to be_falsey

        Timecop.freeze(now - 3.hours) do
          notification.set_seen(user2)
          notification.set_seen(user1)
          notification.destroy_from_member(user2)
          notification.destroy_from_member(user3)
        end
        expect(notification.member_ids).to eq [user1.id]
        expect(notification.unseen?(user1)).to be_falsey
        expect(notification.unseen?(user2)).to be_falsey
        expect(notification.unseen?(user3)).to be_truthy
        expect(notification.deleted?(user1)).to be_falsey
        expect(notification.deleted?(user2)).to be_truthy
        expect(notification.deleted?(user3)).to be_truthy

        notification.reload
        expect(notification.user_settings.length).to eq 3
        expect(notification.send(:find_user_setting, user1.id, "seen_at")).to eq now - 3.hours
        expect(notification.send(:find_user_setting, user1.id, "deleted")).to be_blank
        expect(notification.send(:find_user_setting, user2.id, "seen_at")).to eq now - 3.hours
        expect(notification.send(:find_user_setting, user2.id, "deleted")).to eq now - 3.hours
        expect(notification.send(:find_user_setting, user3.id, "seen_at")).to be_blank
        expect(notification.send(:find_user_setting, user3.id, "deleted")).to eq now - 3.hours
      end
    end
  end

  describe ".undeleted" do
    let!(:n1) do
      create(:ss_notification, member_ids: [ user1.id, user2.id, user3.id ])
    end
    let!(:n2) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user1.id, "seen_at" => Time.zone.now.utc, "deleted" => Time.zone.now.utc },
        ])
    end
    let!(:n3) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user2.id, "deleted" => Time.zone.now.utc },
        ])
    end
    let!(:n4) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user3.id, "seen_at" => Time.zone.now.utc },
        ])
    end
    let!(:n5) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user1.id, "seen_at" => Time.zone.now.utc },
          { "user_id" => user2.id, "deleted" => Time.zone.now.utc },
          { "user_id" => user3.id, "seen_at" => Time.zone.now.utc, "deleted" => Time.zone.now.utc },
        ])
    end

    it do
      expect(described_class.all.count).to eq 5
      expect(described_class.undeleted(user1).count).to eq 4
      expect(described_class.undeleted(user1).pluck(:id)).to include(n1.id, n3.id, n4.id, n5.id)
      expect(described_class.undeleted(user1.id).count).to eq 4
      expect(described_class.undeleted(user2).count).to eq 3
      expect(described_class.undeleted(user2).pluck(:id)).to include(n1.id, n2.id, n4.id)
      expect(described_class.undeleted(user2.id).count).to eq 3
      expect(described_class.undeleted(user3).count).to eq 4
      expect(described_class.undeleted(user3).pluck(:id)).to include(n1.id, n2.id, n3.id, n4.id)
      expect(described_class.undeleted(user3.id).count).to eq 4
    end
  end

  describe ".unseen" do
    let!(:n1) do
      create(:ss_notification, member_ids: [ user1.id, user2.id, user3.id ])
    end
    let!(:n2) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user1.id, "seen_at" => Time.zone.now.utc, "deleted" => Time.zone.now.utc },
        ])
    end
    let!(:n3) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user2.id, "deleted" => Time.zone.now.utc },
        ])
    end
    let!(:n4) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user3.id, "seen_at" => Time.zone.now.utc },
        ])
    end
    let!(:n5) do
      create(
        :ss_notification, member_ids: [ user1.id, user2.id, user3.id ],
        user_settings: [
          { "user_id" => user1.id, "seen_at" => Time.zone.now.utc },
          { "user_id" => user2.id, "deleted" => Time.zone.now.utc },
          { "user_id" => user3.id, "seen_at" => Time.zone.now.utc, "deleted" => Time.zone.now.utc },
        ])
    end

    it do
      expect(described_class.all.count).to eq 5
      expect(described_class.unseen(user1).count).to eq 3
      expect(described_class.unseen(user1).pluck(:id)).to include(n1.id, n3.id, n4.id)
      expect(described_class.unseen(user1.id).count).to eq 3
      expect(described_class.unseen(user2).count).to eq 5
      expect(described_class.unseen(user2).pluck(:id)).to include(n1.id, n2.id, n3.id, n4.id, n5.id)
      expect(described_class.unseen(user2.id).count).to eq 5
      expect(described_class.unseen(user3).count).to eq 3
      expect(described_class.unseen(user3).pluck(:id)).to include(n1.id, n2.id, n3.id)
      expect(described_class.unseen(user3.id).count).to eq 3
    end
  end
end
