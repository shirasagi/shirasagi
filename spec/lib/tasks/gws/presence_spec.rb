require 'spec_helper'

describe Tasks::Gws::Presence, dbscope: :example do
  describe "reset" do
    let!(:site1) { create :gws_group, name: "site1" }
    let!(:site2) { create :gws_group, name: "site2" }

    let!(:group1) { create :gws_group, name: "site1/group1" }
    let!(:group2) { create :gws_group, name: "site1/group2" }
    let!(:group3) { create :gws_group, name: "site1/group2/group3" }
    let!(:group4) { create :gws_group, name: "site2/group4" }

    let!(:user1) { create :gws_user, group_ids: [site1.id] }
    let!(:user2) { create :gws_user, group_ids: [site2.id] }
    let!(:user3) { create :gws_user, group_ids: [group1.id] }
    let!(:user4) { create :gws_user, group_ids: [group2.id] }
    let!(:user5) { create :gws_user, group_ids: [group3.id] }
    let!(:user6) { create :gws_user, group_ids: [group4.id] }

    let!(:user_presence1) { create :gws_user_presence, user: user1, site: site1, state: "available" }
    let!(:user_presence2) { create :gws_user_presence, user: user2, site: site2, state: "unavailable" }
    let!(:user_presence3) { create :gws_user_presence, user: user3, site: site1, state: "leave" }
    let!(:user_presence4) { create :gws_user_presence, user: user4, site: site1, state: "dayoff" }
    let!(:user_presence5) { create :gws_user_presence, user: user5, site: site1, state: "" }
    let!(:user_presence6) { create :gws_user_presence, user: user6, site: site2 }

    before do
      @save = {}
      ENV.each do |key, value|
        @save[key.dup] = value.dup
      end
    end

    after do
      ENV.clear
      @save.each do |key, value|
        ENV[key] = value
      end
    end

    it "all sites" do
      described_class.reset

      user_presence1.reload
      user_presence2.reload
      user_presence3.reload
      user_presence4.reload
      user_presence5.reload
      user_presence6.reload

      expect(user_presence1.state).to eq "unavailable"
      expect(user_presence2.state).to eq "unavailable"
      expect(user_presence3.state).to eq "leave"
      expect(user_presence4.state).to eq "dayoff"
      expect(user_presence5.state).to be_blank
      expect(user_presence6.state).to eq "unavailable"
    end

    it "site1" do
      ENV['site'] = site1.name
      described_class.reset

      user_presence1.reload
      user_presence2.reload
      user_presence3.reload
      user_presence4.reload
      user_presence5.reload
      user_presence6.reload

      expect(user_presence1.state).to eq "unavailable"
      expect(user_presence2.state).to eq "unavailable"
      expect(user_presence3.state).to eq "leave"
      expect(user_presence4.state).to eq "dayoff"
      expect(user_presence5.state).to be_blank
      expect(user_presence6.state).to eq "available"
    end
  end
end
