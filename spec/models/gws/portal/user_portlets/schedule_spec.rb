require 'spec_helper'

describe Gws::Portal::UserPortlet, type: :model, dbscope: :example do
  let!(:portal) { create :gws_portal_user_setting, cur_user: gws_user }
  let!(:portlet) { create :gws_portal_user_portlet, :gws_portal_schedule_portlet, cur_user: gws_user, setting: portal }

  describe "#find_schedule_members" do
    subject { portlet.find_schedule_members(portal).map(&:id) }

    context "without schedule_members" do
      it do
        expect(subject.length).to eq 1
        expect(subject).to include(gws_user.id)
      end
    end

    context "with schedule_members" do
      let!(:user) { create(:gws_user, group_ids: gws_user.group_ids) }

      before do
        portlet.schedule_member_ids = [ user.id ]
        portlet.save!
      end

      it do
        expect(subject.length).to eq 1
        expect(subject).to include(user.id)
      end
    end
  end
end
