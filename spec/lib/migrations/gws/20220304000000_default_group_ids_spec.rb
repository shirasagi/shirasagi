require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20220304000000_default_group_ids.rb")

RSpec.describe SS::Migration20220304000000, dbscope: :example do
  let!(:site) { gws_site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10_001 }
  # let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10_002 }
  # let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10_003 }
  let!(:user1) { create :gws_user }
  let!(:user2) { create :gws_user }
  let!(:user3) { create :gws_user }
  let(:rand_group_id) { rand(100_000..200_000) }

  before do
    expect(user1.gws_default_group_ids).to be_blank
    expect(user2.gws_default_group_ids).to be_blank
    expect(user3.gws_default_group_ids).to be_blank
    Gws::User.find(user2.id).tap do |user|
      user.set(gws_default_group_ids: { site.id.to_s => group1.id.to_s })
    end
    Gws::User.find(user3.id).tap do |user|
      user.set(gws_default_group_ids: { site.id.to_s => rand_group_id.to_s })
    end

    described_class.new.change
  end

  it do
    # put your specs here
    user1.reload
    expect(user1.gws_default_group_ids).to be_blank

    user2.reload
    expect(user2.gws_default_group_ids).to eq(site.id.to_s => group1.id)

    user3.reload
    expect(user3.gws_default_group_ids).to eq(site.id.to_s => rand_group_id)
  end
end
