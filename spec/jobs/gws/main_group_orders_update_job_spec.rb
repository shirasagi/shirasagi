require 'spec_helper'

describe Gws::UserMainGroupOrderUpdateJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:order1) { 10 }
  let!(:order2) { 20 }
  let!(:order3) { 30 }
  let!(:order4) { 40 }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: order1 }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: order2 }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}", order: order3 }

  let!(:user1) { create :gws_user, group_ids: [group1.id] }
  let!(:user2) { create :gws_user, group_ids: [group2.id] }
  let!(:user3) { create :gws_user, group_ids: [group1.id, group2.id, group3.id], in_gws_main_group_id: group3.id }

  it do
    expect(user1.gws_main_group(site).id).to eq group1.id
    expect(user2.gws_main_group(site).id).to eq group2.id
    expect(user3.gws_main_group(site).id).to eq group3.id

    user1.unset(:gws_main_group_orders)
    user2.unset(:gws_main_group_orders)
    user3.unset(:gws_main_group_orders)

    described_class.bind(site_id: site.id).perform_now

    expect(Job::Log.count).to eq 1
    Job::Log.last.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).to include(/update #{user1.name}/)
      expect(log.logs).to include(/update #{user2.name}/)
      expect(log.logs).to include(/update #{user3.name}/)
    end

    user1.reload
    user2.reload
    user3.reload

    expect(user1.gws_main_group_orders[site.id.to_s]).to eq order1
    expect(user2.gws_main_group_orders[site.id.to_s]).to eq order2
    expect(user3.gws_main_group_orders[site.id.to_s]).to eq order3

    group1.order = order4
    group1.update!

    described_class.bind(site_id: site.id).perform_now

    expect(Job::Log.count).to eq 2
    Job::Log.last.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).to include(/update #{user1.name}/)
      expect(log.logs).not_to include(/update #{user2.name}/)
      expect(log.logs).not_to include(/update #{user3.name}/)
    end

    user1.reload
    user2.reload
    user3.reload

    expect(user1.gws_main_group_orders[site.id.to_s]).to eq order4
    expect(user2.gws_main_group_orders[site.id.to_s]).to eq order2
    expect(user3.gws_main_group_orders[site.id.to_s]).to eq order3
  end

  it "clears stored order when main group is missing" do
    described_class.bind(site_id: site.id).perform_now

    user1.reload
    expect(user1.gws_main_group_orders[site.id.to_s]).to eq order1

    # グループが削除された後、ユーザーのgroup_idsに削除されたグループIDが残っているが、
    # gws_main_group(site)がnilを返すケースをシミュレート
    group1.destroy

    expect do
      described_class.bind(site_id: site.id).perform_now
    end.to change { Job::Log.count }.by(1)

    Job::Log.last.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
      expect(log.logs).to include(/clear #{Regexp.escape(user1.long_name)}/)
    end

    user1.reload
    expect(user1.gws_main_group_orders[site.id.to_s]).to be_nil
  end

  it "skips users whose main group is missing" do
    orphan_group = create :gws_group, name: "#{site.name}/#{unique_id}", order: 10
    orphan_user = create :gws_user, group_ids: [orphan_group.id], in_gws_main_group_id: orphan_group.id

    orphan_user.unset(:gws_main_group_orders)
    orphan_group.destroy

    expect do
      described_class.bind(site_id: site.id).perform_now
    end.not_to raise_error

    log = Job::Log.last
    expect(log).to be_present
    expect(log.logs).to include(/INFO -- : .* Started Job/)
    expect(log.logs).to include(/INFO -- : .* Completed Job/)
    expect(log.logs).not_to include(/update #{orphan_user.name}/)

    orphan_user.reload
    expect(orphan_user.gws_main_group_orders).to be_blank
  end
end
