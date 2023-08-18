require 'spec_helper'

describe Workflow::ReminderJob, dbscope: :example do
  let!(:site) { cms_site }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "when approve_remind_state is disabled" do
    before do
      site.approve_remind_state = nil
      site.approve_remind_later = nil
      site.save!
    end

    it do
      expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::Task.all.count).to eq 1
      Cms::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.name).to eq "workflow:reminder"
        expect(task.state).to eq "completed"
      end

      expect(ActionMailer::Base.deliveries.length).to eq 0
      expect(SS::Notification.all.count).to eq 0
    end
  end

  context "when approve_remind_state is enabled" do
    let!(:user1) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
    let!(:user2) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
    let!(:user3) { create :cms_test_user, group_ids: cms_user.group_ids, cms_role_ids: cms_user.cms_role_ids }
    let!(:node) { create :article_node_page, cur_site: site }
    let!(:page1) { create :article_page, cur_site: site, cur_node: node, state: "closed" }
    let!(:page2) { create :article_page, cur_site: site, cur_node: node, state: "closed" }

    before do
      site.mypage_domain = unique_domain
      site.approve_remind_state = "enabled"
      site.approve_remind_later = "1.day"
      site.save!

      # テストの再現性を高めるために、ミリ秒部を 0 クリアする
      page1.set(updated: page1.updated.change(usec: 0).utc)
      page2.set(updated: page2.updated.change(usec: 0).utc)
    end

    context "there are no requested pages" do
      it do
        expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output.to_stdout

        expect(Job::Log.all.count).to eq 1
        Job::Log.all.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Task.all.count).to eq 1
        Cms::Task.all.first.tap do |task|
          expect(task.site_id).to eq site.id
          expect(task.name).to eq "workflow:reminder"
          expect(task.state).to eq "completed"
        end

        expect(ActionMailer::Base.deliveries.length).to eq 0
        expect(SS::Notification.all.count).to eq 0

        page1.reload
        expect(page1.workflow_reminder_sent_at).to be_blank
        page2.reload
        expect(page2.workflow_reminder_sent_at).to be_blank
      end
    end

    context "with my_group" do
      before do
        page1.workflow_user_id = user1.id
        page1.workflow_state = "request"
        # 2 人に申請を送り、1 人は承認済み。もう一人は未承認。
        page1.workflow_approvers = [
          { level: 1, user_id: user2.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: "" },
          { level: 1, user_id: user3.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_APPROVE, comment: "ok" }
        ]
        page1.workflow_required_counts = [ false ]
        page1.save!
      end

      context "督促期限切れ直前" do
        let(:time) do
          time = page1.updated + SS::Duration.parse(site.approve_remind_later)
          time.change(usec: 0)
        end

        it do
          Timecop.freeze(time) do
            expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output.to_stdout
          end

          expect(Job::Log.all.count).to eq 1
          Job::Log.all.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Task.all.count).to eq 1
          Cms::Task.all.first.tap do |task|
            expect(task.site_id).to eq site.id
            expect(task.name).to eq "workflow:reminder"
            expect(task.state).to eq "completed"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 0
          expect(SS::Notification.all.count).to eq 0

          page1.reload
          expect(page1.workflow_reminder_sent_at).to be_blank
          page2.reload
          expect(page2.workflow_reminder_sent_at).to be_blank
        end
      end

      context "督促期限切れ直後" do
        let(:time) do
          time = page1.updated + SS::Duration.parse(site.approve_remind_later)
          time.change(usec: 0) + 1.second
        end

        it do
          Timecop.freeze(time) do
            expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output(include(user2.long_name)).to_stdout
          end

          expect(Job::Log.all.count).to eq 1
          Job::Log.all.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Task.all.count).to eq 1
          Cms::Task.all.first.tap do |task|
            expect(task.site_id).to eq site.id
            expect(task.name).to eq "workflow:reminder"
            expect(task.state).to eq "completed"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          ActionMailer::Base.deliveries.first.tap do |mail|
            expect(mail.from.first).to eq user1.email
            expect(mail.to.first).to eq user2.email
            expect(mail.subject).to eq I18n.t("workflow.notice.remind.subject", page_name: page1.name, site_name: site.name)
            expect(mail.body.multipart?).to be_falsey
            expect(mail.body.raw_source).to include(user1.name, page1.name, site.mypage_domain, page1.private_show_path)
          end
          expect(SS::Notification.all.count).to eq 1
          SS::Notification.all.first.tap do |notifiction|
            expect(notifiction.group_id).to be_blank
            expect(notifiction.member_ids).to eq [ user2.id ]
            expect(notifiction.user_id).to eq user1.id
            I18n.t("workflow.notice.remind.subject", page_name: page1.name, site_name: site.name).tap do |subject|
              expect(notifiction.subject).to eq subject
            end
            expect(notifiction.text).to include(user1.name, page1.name, page1.private_show_path)
            expect(notifiction.html).to be_blank
            expect(notifiction.format).to eq "text"
            expect(notifiction.user_settings).to be_blank
            expect(notifiction.state).to eq "public"
            expect(notifiction.send_date).to eq time
            expect(notifiction.url).to be_blank
            expect(notifiction.reply_module).to be_blank
            expect(notifiction.reply_model).to be_blank
            expect(notifiction.reply_item_id).to be_blank
          end

          page1.reload
          expect(page1.workflow_reminder_sent_at).to eq time
          page2.reload
          expect(page2.workflow_reminder_sent_at).to be_blank
        end
      end

      context "2回目の督促: 前回の督促を送ってからちょうど一日" do
        let(:workflow_reminder_sent_at) do
          time = page1.updated + SS::Duration.parse(site.approve_remind_later) + 1.minute
          time.change(usec: 0)
        end
        let(:time) do
          time = page1.workflow_reminder_sent_at + 1.day
          time.change(usec: 0)
        end

        before do
          page1.set(workflow_reminder_sent_at: workflow_reminder_sent_at.utc)
        end

        it do
          Timecop.freeze(time) do
            expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output.to_stdout
          end

          expect(Job::Log.all.count).to eq 1
          Job::Log.all.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Task.all.count).to eq 1
          Cms::Task.all.first.tap do |task|
            expect(task.site_id).to eq site.id
            expect(task.name).to eq "workflow:reminder"
            expect(task.state).to eq "completed"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 0
          expect(SS::Notification.all.count).to eq 0

          page1.reload
          expect(page1.workflow_reminder_sent_at).to eq workflow_reminder_sent_at
          page2.reload
          expect(page2.workflow_reminder_sent_at).to be_blank
        end
      end

      context "2回目の督促: 前回の督促を送ってからちょうど一日以上経過" do
        let(:workflow_reminder_sent_at) do
          time = page1.updated + SS::Duration.parse(site.approve_remind_later) + 1.minute
          time.change(usec: 0)
        end
        let(:time) do
          time = page1.workflow_reminder_sent_at + 1.day + 1.second
          time.change(usec: 0)
        end

        before do
          page1.set(workflow_reminder_sent_at: workflow_reminder_sent_at.utc)
        end

        it do
          Timecop.freeze(time) do
            expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output(include(user2.long_name)).to_stdout
          end

          expect(Job::Log.all.count).to eq 1
          Job::Log.all.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Task.all.count).to eq 1
          Cms::Task.all.first.tap do |task|
            expect(task.site_id).to eq site.id
            expect(task.name).to eq "workflow:reminder"
            expect(task.state).to eq "completed"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          ActionMailer::Base.deliveries.first.tap do |mail|
            expect(mail.from.first).to eq user1.email
            expect(mail.to.first).to eq user2.email
            expect(mail.subject).to eq I18n.t("workflow.notice.remind.subject", page_name: page1.name, site_name: site.name)
            expect(mail.body.multipart?).to be_falsey
            expect(mail.body.raw_source).to include(user1.name, page1.name, site.mypage_domain, page1.private_show_path)
          end
          expect(SS::Notification.all.count).to eq 1
          SS::Notification.all.first.tap do |notifiction|
            expect(notifiction.group_id).to be_blank
            expect(notifiction.member_ids).to eq [ user2.id ]
            expect(notifiction.user_id).to eq user1.id
            I18n.t("workflow.notice.remind.subject", page_name: page1.name, site_name: site.name).tap do |subject|
              expect(notifiction.subject).to eq subject
            end
            expect(notifiction.text).to include(user1.name, page1.name, page1.private_show_path)
            expect(notifiction.html).to be_blank
            expect(notifiction.format).to eq "text"
            expect(notifiction.user_settings).to be_blank
            expect(notifiction.state).to eq "public"
            expect(notifiction.send_date).to eq time
            expect(notifiction.url).to be_blank
            expect(notifiction.reply_module).to be_blank
            expect(notifiction.reply_model).to be_blank
            expect(notifiction.reply_item_id).to be_blank
          end

          page1.reload
          expect(page1.workflow_reminder_sent_at).to eq time
          page2.reload
          expect(page2.workflow_reminder_sent_at).to be_blank
        end
      end
    end

    context "with multi-stage workflow" do
      before do
        page1.workflow_user_id = user1.id
        page1.workflow_state = Workflow::Approver::WORKFLOW_STATE_REQUEST
        # 3 段目のuser2 が差し戻して、現在は 2 段目の承認待ち
        page1.workflow_approvers = [
          { level: 1, user_id: user2.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_APPROVE, comment: unique_id },
          { level: 2, user_id: user3.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: "" },
          { level: 3, user_id: user2.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_REMAND, comment: unique_id },
          { level: 3, user_id: user3.id, editable: "", state: Workflow::Approver::WORKFLOW_STATE_OTHER_REMANDED, comment: "" }
        ]
        page1.workflow_required_counts = [ false, false, false ]
        page1.save!
      end

      context "督促期限切れ直後" do
        let(:time) do
          time = page1.updated + SS::Duration.parse(site.approve_remind_later)
          time.change(usec: 0) + 1.second
        end

        it do
          Timecop.freeze(time) do
            expect { Workflow::ReminderJob.bind(site_id: site).perform_now }.to output(include(user3.long_name)).to_stdout
          end

          expect(Job::Log.all.count).to eq 1
          Job::Log.all.first.tap do |log|
            expect(log.logs).to include(/INFO -- : .* Started Job/)
            expect(log.logs).to include(/INFO -- : .* Completed Job/)
          end

          expect(Cms::Task.all.count).to eq 1
          Cms::Task.all.first.tap do |task|
            expect(task.site_id).to eq site.id
            expect(task.name).to eq "workflow:reminder"
            expect(task.state).to eq "completed"
          end

          expect(ActionMailer::Base.deliveries.length).to eq 1
          ActionMailer::Base.deliveries.first.tap do |mail|
            expect(mail.from.first).to eq user1.email
            expect(mail.to.first).to eq user3.email
            expect(mail.subject).to eq I18n.t("workflow.notice.remind.subject", page_name: page1.name, site_name: site.name)
            expect(mail.body.multipart?).to be_falsey
            expect(mail.body.raw_source).to include(user1.name, page1.name, site.mypage_domain, page1.private_show_path)
          end
          expect(SS::Notification.all.count).to eq 1
          SS::Notification.all.first.tap do |notifiction|
            expect(notifiction.group_id).to be_blank
            expect(notifiction.member_ids).to eq [ user3.id ]
            expect(notifiction.user_id).to eq user1.id
            I18n.t("workflow.notice.remind.subject", page_name: page1.name, site_name: site.name).tap do |subject|
              expect(notifiction.subject).to eq subject
            end
            expect(notifiction.text).to include(user1.name, page1.name, page1.private_show_path)
            expect(notifiction.html).to be_blank
            expect(notifiction.format).to eq "text"
            expect(notifiction.user_settings).to be_blank
            expect(notifiction.state).to eq "public"
            expect(notifiction.send_date).to eq time
            expect(notifiction.url).to be_blank
            expect(notifiction.reply_module).to be_blank
            expect(notifiction.reply_model).to be_blank
            expect(notifiction.reply_item_id).to be_blank
          end

          page1.reload
          expect(page1.workflow_reminder_sent_at).to eq time
          page2.reload
          expect(page2.workflow_reminder_sent_at).to be_blank
        end
      end
    end
  end
end
