require 'spec_helper'

describe Gws::Board::NotificationJob, dbscope: :example do
  let(:site) { gws_site }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:user1) { create(:gws_user, group_ids: [ site.id ]) }
  let!(:cate) { create(:gws_board_category, subscribed_member_ids: [ user1.id ]) }
  let!(:topic) do
    create(
      :gws_board_topic, category_ids: [ cate.id ], notify_state: "enabled",
      state: "public", release_date: nil, close_date: nil, deleted: nil
    )
  end

  describe '#perform' do
    context 'when notify_state is disabled' do
      before do
        topic.notify_state = "disabled"
        topic.save!
      end

      it do
        described_class.bind(site_id: site.id).perform_now

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context 'when notify_state is enabled but state is closed' do
      before do
        topic.state = "closed"
        topic.save!
      end

      it do
        described_class.bind(site_id: site.id).perform_now

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context 'when notify_state is enabled but deleted' do
      before do
        topic.deleted = now - 1.second
        topic.save!
      end

      it do
        described_class.bind(site_id: site.id).perform_now

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context 'when notify_state is enabled' do
      it do
        described_class.bind(site_id: site.id).perform_now

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(include("INFO -- : Started Job"))
          expect(log.logs).to include(include("INFO -- : Completed Job"))
        end

        expect(SS::Notification.all.count).to eq 1
        notice = SS::Notification.first
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user1.id ]
        expect(notice.user_id).to be_blank
        expect(notice.subject).to eq I18n.t("gws_notification.gws/board/topic.subject", name: topic.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/board/-/-/topics/#{topic.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end
    end

    context 'when release_date and close_date are presented' do
      let(:release_date) { now + 1.day }
      let(:close_date) { release_date + 1.day }

      before do
        topic.release_date = release_date
        topic.close_date = close_date
        topic.save!
      end

      context 'when it is before release_date' do
        it do
          travel_to(release_date - 1.second) do
            described_class.bind(site_id: site.id).perform_now

            expect(Job::Log.count).to eq 1
            Job::Log.first.tap do |log|
              expect(log.logs).to include(include("INFO -- : Started Job"))
              expect(log.logs).to include(include("INFO -- : Completed Job"))
            end

            expect(SS::Notification.all.count).to eq 0
          end
        end
      end

      context 'when it is at release_date' do
        it do
          travel_to(release_date) do
            described_class.bind(site_id: site.id).perform_now

            expect(Job::Log.count).to eq 1
            Job::Log.first.tap do |log|
              expect(log.logs).to include(include("INFO -- : Started Job"))
              expect(log.logs).to include(include("INFO -- : Completed Job"))
            end

            expect(SS::Notification.all.count).to eq 1
          end
        end
      end

      context 'when it is before close_date' do
        it do
          travel_to(close_date - 1.second) do
            described_class.bind(site_id: site.id, user_id: gws_user.id).perform_now

            expect(Job::Log.count).to eq 1
            Job::Log.first.tap do |log|
              expect(log.logs).to include(include("INFO -- : Started Job"))
              expect(log.logs).to include(include("INFO -- : Completed Job"))
            end

            expect(SS::Notification.all.count).to eq 1
            notice = SS::Notification.first
            expect(notice.group_id).to eq site.id
            expect(notice.member_ids).to eq [ user1.id ]
            expect(notice.user_id).to eq gws_user.id
          end
        end
      end

      context 'when it is at close_date' do
        it do
          travel_to(close_date) do
            described_class.bind(site_id: site.id).perform_now

            expect(Job::Log.count).to eq 1
            Job::Log.first.tap do |log|
              expect(log.logs).to include(include("INFO -- : Started Job"))
              expect(log.logs).to include(include("INFO -- : Completed Job"))
            end

            expect(SS::Notification.all.count).to eq 0
          end
        end
      end
    end
  end
end
