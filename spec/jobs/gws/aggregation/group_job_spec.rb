require 'spec_helper'

describe Gws::Aggregation::GroupJob, dbscope: :example do
  let!(:site) { gws_site }

  let(:group1) { Gws::Group.find_by(name: "シラサギ市") }
  let(:group2) { Gws::Group.find_by(name: "シラサギ市/企画政策部") }
  let(:group3) { Gws::Group.find_by(name: "シラサギ市/企画政策部/政策課") }
  let(:group4) { create(:gws_group, name: "シラサギ市/企画政策部/広報課") }
  let(:group5) { create(:gws_group, name: "シラサギ市/企画政策部/広報課/担当1") }
  let(:group6) { create(:gws_group, name: "シラサギ市/企画政策部/広報課/担当2") }

  let!(:user1) { create(:gws_user, group_ids: [group4.id], title_ids: [title1.id]) }
  let!(:user2) { create(:gws_user, group_ids: [group4.id], title_ids: [title2.id]) }
  let(:user3) { create(:gws_user, group_ids: [group4.id], title_ids: [title3.id]) }
  let(:user4) { create(:gws_user, group_ids: [group4.id], title_ids: [title4.id]) }

  let!(:title1) { create :gws_user_title, name: "部長", order: 40 }
  let!(:title2) { create :gws_user_title, name: "課長", order: 30 }
  let!(:title3) { create :gws_user_title, name: "係長", order: 20 }
  let!(:title4) { create :gws_user_title, name: "主任", order: 10 }
  let!(:title5) { create :gws_user_title, name: "担当", order: 5 }

  let(:time1) { Time.zone.now }
  let(:time2) { time1.advance(months: 1) }
  let(:time3) { time1.advance(months: 2) }
  let(:time4) { time1.advance(months: 3) }
  let(:time5) { time1.advance(months: 4) }
  let(:time6) { time1.advance(months: 5) }

  describe '#perform' do
    context "update aggregation group" do
      it do
        Timecop.freeze(time1) do
          group4
          described_class.bind(site_id: site.id).perform_now
          expect(Gws::Aggregation::Group.count).to eq 4
        end

        Timecop.freeze(time2) do
          # no changed
          described_class.bind(site_id: site.id).perform_now
          expect(Gws::Aggregation::Group.count).to eq 4
        end

        Timecop.freeze(time3) do
          # add users
          user3
          user4

          described_class.bind(site_id: site.id).perform_now
          expect(Gws::Aggregation::Group.count).to eq 5
        end

        Timecop.freeze(time4) do
          # user title changed
          user3.title_ids = [title5.id]
          user3.update!
          user3.reload

          described_class.bind(site_id: site.id).perform_now
          expect(Gws::Aggregation::Group.count).to eq 6
        end

        Timecop.freeze(time5) do
          # move user
          user3.group_ids = [group2.id]
          user3.update!
          user3.reload

          described_class.bind(site_id: site.id).perform_now
          expect(Gws::Aggregation::Group.count).to eq 8
        end

        Timecop.freeze(time6) do
          # delete user
          user4.account_expiration_date = Time.zone.now
          user4.update!
          user4.reload

          described_class.bind(site_id: site.id).perform_now
          expect(Gws::Aggregation::Group.count).to eq 9
        end

        # time1
        aggregation_groups = Gws::Aggregation::Group.active_at(time1 + 1.second)
        users = aggregation_groups.find_group(group4.id).ordered_users
        expect(users.map(&:name)).to eq [user1.name, user2.name]

        # time2
        aggregation_groups = Gws::Aggregation::Group.active_at(time2 + 1.second)
        users = aggregation_groups.find_group(group4.id).ordered_users
        expect(users.map(&:name)).to eq [user1.name, user2.name]

        # time3
        aggregation_groups = Gws::Aggregation::Group.active_at(time3 + 1.second)
        users = aggregation_groups.find_group(group4.id).ordered_users
        expect(users.map(&:name)).to eq [user1.name, user2.name, user3.name, user4.name]

        # time4
        aggregation_groups = Gws::Aggregation::Group.active_at(time4 + 1.second)
        users = aggregation_groups.find_group(group4.id).ordered_users
        expect(users.map(&:name)).to eq [user1.name, user2.name, user4.name, user3.name]

        # time5
        aggregation_groups = Gws::Aggregation::Group.active_at(time5 + 1.second)
        users = aggregation_groups.find_group(group4.id).ordered_users
        expect(users.map(&:name)).to eq [user1.name, user2.name, user4.name]

        # time6
        aggregation_groups = Gws::Aggregation::Group.active_at(time6 + 1.second)
        users = aggregation_groups.find_group(group4.id).ordered_users
        expect(users.map(&:name)).to eq [user1.name, user2.name]
      end
    end

    it do
      Timecop.freeze(time1) do
        group4
        described_class.bind(site_id: site.id).perform_now
        expect(Gws::Aggregation::Group.count).to eq 4
      end

      Timecop.freeze(time2) do
        # no changed
        described_class.bind(site_id: site.id).perform_now
        expect(Gws::Aggregation::Group.count).to eq 4
      end

      Timecop.freeze(time3) do
        # add group
        group5
        group6
        described_class.bind(site_id: site.id).perform_now
        expect(Gws::Aggregation::Group.count).to eq 6
      end

      Timecop.freeze(time4) do
        # move group
        group4.name = "シラサギ市/企画政策部/DX推進広報課"
        group4.update!
        group4.reload

        described_class.bind(site_id: site.id).perform_now
        expect(Gws::Aggregation::Group.count).to eq 9
      end

      Timecop.freeze(time5) do
        # delete group
        group4.expiration_date = Time.zone.now
        group4.update!
        group4.reload

        described_class.bind(site_id: site.id).perform_now
        expect(Gws::Aggregation::Group.count).to eq 9
      end

      Timecop.freeze(time6) do
        # reset group
        group4.expiration_date = nil
        group4.update!
        group4.reload

        described_class.bind(site_id: site.id).perform_now
        expect(Gws::Aggregation::Group.count).to eq 10
      end

      groups = Gws::Aggregation::Group.active_at(time1 + 1.second)
      expect(groups.map(&:name)).to eq %w(
        シラサギ市
        シラサギ市/企画政策部
        シラサギ市/企画政策部/広報課
        シラサギ市/企画政策部/政策課)

      groups = Gws::Aggregation::Group.active_at(time2 + 1.second)
      expect(groups.map(&:name)).to eq %w(
        シラサギ市
        シラサギ市/企画政策部
        シラサギ市/企画政策部/広報課
        シラサギ市/企画政策部/政策課)

      groups = Gws::Aggregation::Group.active_at(time3 + 1.second)
      expect(groups.map(&:name)).to eq %w(
        シラサギ市
        シラサギ市/企画政策部
        シラサギ市/企画政策部/広報課
        シラサギ市/企画政策部/広報課/担当1
        シラサギ市/企画政策部/広報課/担当2
        シラサギ市/企画政策部/政策課)

      groups = Gws::Aggregation::Group.active_at(time4 + 1.second)
      expect(groups.map(&:name)).to eq %w(
        シラサギ市
        シラサギ市/企画政策部
        シラサギ市/企画政策部/DX推進広報課
        シラサギ市/企画政策部/DX推進広報課/担当1
        シラサギ市/企画政策部/DX推進広報課/担当2
        シラサギ市/企画政策部/政策課)

      groups = Gws::Aggregation::Group.active_at(time5 + 1.second)
      expect(groups.map(&:name)).to eq %w(
        シラサギ市
        シラサギ市/企画政策部
        シラサギ市/企画政策部/DX推進広報課/担当1
        シラサギ市/企画政策部/DX推進広報課/担当2
        シラサギ市/企画政策部/政策課)

      groups = Gws::Aggregation::Group.active_at(time6 + 1.second)
      expect(groups.map(&:name)).to eq %w(
        シラサギ市
        シラサギ市/企画政策部
        シラサギ市/企画政策部/DX推進広報課
        シラサギ市/企画政策部/DX推進広報課/担当1
        シラサギ市/企画政策部/DX推進広報課/担当2
        シラサギ市/企画政策部/政策課)
    end
  end
end
