require 'spec_helper'

describe Gws::StaffRecord::CopySituationJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:user) { create(:gws_user, group_ids: [ site.id ]) }
  let!(:year) { create(:gws_staff_record_year, cur_site: site, cur_user: user) }

  describe '#perform' do
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:user11) { create(:gws_user, group_ids: [ group1.id ]) }
    let!(:user12) { create(:gws_user, group_ids: [ group1.id ]) }
    let!(:user13) { create(:gws_user, group_ids: [ group1.id ]) }
    let!(:user21) { create(:gws_user, group_ids: [ group2.id ]) }
    let!(:user22) { create(:gws_user, group_ids: [ group2.id ]) }

    it do
      described_class.bind(site_id: site).perform_now(year.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::StaffRecord::Group.count).to eq 3
      Gws::StaffRecord::Group.find_by(name: site.name).tap do |g|
        expect(g.name).to eq site.name
      end
      Gws::StaffRecord::Group.find_by(name: group1.name).tap do |g|
        expect(g.name).to eq group1.name
      end
      Gws::StaffRecord::Group.find_by(name: group2.name).tap do |g|
        expect(g.name).to eq group2.name
      end
      expect(Gws::StaffRecord::User.count).to eq 6
      Gws::StaffRecord::User.find_by(name: user.name).tap do |u|
        expect(u.name).to eq user.name
      end
      Gws::StaffRecord::User.find_by(name: user11.name).tap do |u|
        expect(u.name).to eq user11.name
      end
    end
  end
end
