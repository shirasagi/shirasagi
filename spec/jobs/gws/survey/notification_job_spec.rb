require 'spec_helper'

describe Gws::Survey::NotificationJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }

  describe '#perform' do
    context "usual case" do
      let(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
      let!(:item) do
        create(
          :gws_survey_form, cur_site: site, notification_notice_state: "enabled",
          state: "public", readable_setting_range: "select", readable_member_ids: [ user1.id ]
        )
      end

      context "without any options" do
        it do
          # item 作成時にジョブが実行され通知が送られているはず
          expect(Gws::Job::Log.count).to eq 1
          Gws::Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('1件のアンケートがあります。'))
          end
          expect(SS::Notification.all.count).to eq 1
          SS::Notification.all.first.tap do |notice|
            subject_key = "gws_notification.#{Gws::Survey::Form.model_name.i18n_key}.subject"
            subject = I18n.t(subject_key, name: item.name, default: item.name)
            expect(notice.subject).to eq subject
            expect(notice.member_ids).to include(user1.id)
          end

          # すでに通知は送られているので、通知送信ジョブを実行しても、通知は送られない
          described_class.bind(site_id: site).perform_now

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.reorder(created: -1).first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('0件のアンケートがあります。'))
          end

          expect(SS::Notification.all.count).to eq 1
        end
      end

      context "with resend" do
        it do
          # item 作成時にジョブが実行され通知が送られているはず
          expect(Gws::Job::Log.count).to eq 1
          expect(SS::Notification.all.count).to eq 1

          # 「再送」オプションを有効にすると、通知は送られる
          described_class.bind(site_id: site).perform_now(resend: true)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.reorder(created: -1).first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('1件のアンケートがあります。'))
          end

          expect(SS::Notification.all.count).to eq 2
          SS::Notification.all.reorder(created: -1).first.tap do |notice|
            subject_key = "gws_notification.#{Gws::Survey::Form.model_name.i18n_key}.subject"
            subject = I18n.t(subject_key, name: item.name, default: item.name)
            expect(notice.subject).to eq subject
            expect(notice.member_ids).to include(user1.id)
          end
        end
      end

      context "with resend and unanswered_only" do
        it do
          # item 作成時にジョブが実行され通知が送られているはず
          expect(Gws::Job::Log.count).to eq 1
          expect(SS::Notification.all.count).to eq 1

          item.set_answered!(user1)
          described_class.bind(site_id: site).perform_now(resend: true, unanswered_only: true)

          expect(Gws::Job::Log.count).to eq 2
          Gws::Job::Log.reorder(created: -1).first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('1件のアンケートがあります。'))
            expect(log.logs).to include(include('通知対象ユーザーが見つかりません'))
          end

          # 通知は送られていない
          expect(SS::Notification.all.count).to eq 1
        end
      end
    end

    context "with release date" do
      let(:now) { Time.zone.now.beginning_of_minute }
      let(:release_date) { now + 1.hour }
      let(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids }
      let!(:item) do
        create(
          :gws_survey_form, cur_site: site, notification_notice_state: "enabled", release_date: release_date,
          state: "public", readable_setting_range: "select", readable_member_ids: [ user1.id ]
        )
      end

      context "before release date" do
        it do
          Timecop.freeze(release_date - 1.second) do
            described_class.bind(site_id: site).perform_now
          end

          expect(Gws::Job::Log.count).to eq 1
          Gws::Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('0件のアンケートがあります。'))
          end

          expect(SS::Notification.all.count).to eq 0
        end
      end

      context "at release date" do
        it do
          Timecop.freeze(release_date) do
            described_class.bind(site_id: site).perform_now
          end

          expect(Gws::Job::Log.count).to eq 1
          Gws::Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('1件のアンケートがあります。'))
          end

          expect(SS::Notification.all.count).to eq 1
          SS::Notification.all.first.tap do |notice|
            subject_key = "gws_notification.#{Gws::Survey::Form.model_name.i18n_key}.subject"
            subject = I18n.t(subject_key, name: item.name, default: item.name)
            expect(notice.subject).to eq subject
            expect(notice.member_ids).to include(user1.id)
          end
        end
      end

      context "at release date with resend and unanswered_only" do
        it do
          Timecop.freeze(release_date) do
            described_class.bind(site_id: site).perform_now(resend: true, unanswered_only: true)
          end

          expect(Gws::Job::Log.count).to eq 1
          Gws::Job::Log.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
            expect(log.logs).to include(include('1件のアンケートがあります。'))
          end

          expect(SS::Notification.all.count).to eq 1
          SS::Notification.all.first.tap do |notice|
            subject_key = "gws_notification.#{Gws::Survey::Form.model_name.i18n_key}.subject"
            subject = I18n.t(subject_key, name: item.name, default: item.name)
            expect(notice.subject).to eq subject
            expect(notice.member_ids).to include(user1.id)
          end
        end
      end
    end
  end
end
