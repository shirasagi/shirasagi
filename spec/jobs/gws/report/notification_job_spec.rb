require 'spec_helper'

describe Gws::Report::NotificationJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let(:item) { create(:gws_report_file) }
  let(:added_member_ids) { [user.id] }
  let(:removed_member_ids) { [user2.id] }

  describe '#perform' do
    context 'normal notify' do
      it do
        job = Gws::Report::NotificationJob.bind(site_id: site)
        job.perform_now(item.id.to_s, added_member_ids, removed_member_ids)

        Job::Log.first.tap do |log|
          expect(log.attributes[:logs]).to be_empty
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
        expect(Job::Log.count).to eq 1

        notices = SS::Notification.all.entries
        notices[0].tap do |notice|
          expect(notice.member_ids).to match removed_member_ids
        end
        notices[1].tap do |notice|
          expect(notice.member_ids).to match added_member_ids
        end
        expect(notices.size).to eq 2
      end
    end
  end
end
