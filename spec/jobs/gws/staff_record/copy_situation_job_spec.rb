require 'spec_helper'

describe Gws::StaffRecord::CopySituationJob, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:user) { create(:gws_user, group_ids: [ site.id ]) }
  let!(:year) { create(:gws_staff_record_year, cur_site: site, cur_user: user) }

  describe '#perform' do
    let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
    let!(:user11) { create(:gws_user, group_ids: [ group1.id ], title_ids: [ user_title11.id ]) }
    let!(:user12) { create(:gws_user, group_ids: [ group1.id ], title_ids: [ user_title12.id ]) }
    let!(:user13) { create(:gws_user, group_ids: [ group1.id ]) }
    let!(:user21) { create(:gws_user, group_ids: [ group2.id ], title_ids: [ user_title21.id ]) }
    let!(:user22) { create(:gws_user, group_ids: [ group2.id ], title_ids: [ user_title21.id ]) }
    let!(:user_title11) { create(:gws_user_title, cur_site: site) }
    let!(:user_title12) { create(:gws_user_title, cur_site: site) }
    let!(:user_title21) { create(:gws_user_title, cur_site: site) }

    it do
      described_class.bind(site_id: site).perform_now(year.id.to_s)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::StaffRecord::Group.count).to eq 3
      Gws::StaffRecord::Group.find_by(name: site.trailing_name).tap do |g|
        expect(g.name).to eq site.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group1.trailing_name).tap do |g|
        expect(g.name).to eq group1.trailing_name
      end
      Gws::StaffRecord::Group.find_by(name: group2.trailing_name).tap do |g|
        expect(g.name).to eq group2.trailing_name
      end
      expect(Gws::StaffRecord::User.count).to eq 6
      Gws::StaffRecord::User.find_by(name: user.name).tap do |u|
        expect(u.name).to eq user.name
        expect(u.title(site)).to be_nil
      end
      Gws::StaffRecord::User.find_by(name: user11.name).tap do |u|
        expect(u.name).to eq user11.name
        expect(u.title(site)).to be_present
        expect(u.title(site).name).to eq user_title11.name
      end
      expect(Gws::StaffRecord::UserTitle.count).to eq 3
      Gws::StaffRecord::UserTitle.find_by(name: user_title11.name).tap do |u|
        expect(u.name).to eq user_title11.name
      end
    end
  end
end
