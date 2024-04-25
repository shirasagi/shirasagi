require 'spec_helper'

describe "my_group", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:layout) { create_cms_layout }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let!(:user1) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:workflow_comment) { unique_id }
  let(:approve_comment1) { unique_id }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "with article/page" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let(:release_date) { Time.zone.at(1.day.from_now.to_i) }
    let!(:item) do
      create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed', release_date: release_date)
    end
    let(:show_path) { article_page_path(site, node, item) }

    context "when release page is approved before release date" do
      it do
        expect(item.backups.count).to eq 1

        #
        # admin: send request
        #
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          click_on user1.long_name
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.release_date).to eq release_date
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        # no backups are created while requesting approve
        expect(item.backups.count).to eq 1

        expect(Sys::MailLog.count).to eq 1
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user1.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user1: approve request
        #
        login_user user1
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "ready"
        expect(item.release_date).to eq release_date
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
        # backup is created
        expect(item.backups.count).to eq 2

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user1.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item.name)
        end
      end
    end

    context "when release page is approved after release date" do
      it do
        Timecop.travel(release_date + 1.second) do
          expect(item.backups.count).to eq 1

          #
          # admin: send request
          #
          login_cms_user
          visit show_path

          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(user1.long_name)
            click_on user1.long_name
          end
          within ".mod-workflow-request" do
            fill_in "workflow[comment]", with: workflow_comment
            click_on I18n.t("workflow.buttons.request")
          end

          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
          expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)

          item.reload
          expect(item.workflow_user_id).to eq cms_user.id
          expect(item.workflow_state).to eq "request"
          expect(item.state).to eq "closed"
          expect(item.release_date).to eq release_date
          expect(item.workflow_approvers.count).to eq 1
          expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
          # no backups are created while requesting approve
          expect(item.backups.count).to eq 1

          expect(Sys::MailLog.count).to eq 1
          expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
          ActionMailer::Base.deliveries.last.tap do |mail|
            expect(mail.from.first).to eq cms_user.email
            expect(mail.to.first).to eq user1.email
            expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
            expect(mail.body.multipart?).to be_falsey
            expect(mail.body.raw_source).to include(cms_user.name)
            expect(mail.body.raw_source).to include(item.name)
            expect(mail.body.raw_source).to include(workflow_comment)
          end

          #
          # user1: approve request
          #
          login_user user1
          visit show_path

          within ".mod-workflow-approve" do
            fill_in "remand[comment]", with: approve_comment1
            click_on I18n.t("workflow.buttons.approve")
          end

          expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

          item.reload
          expect(item.workflow_state).to eq "approve"
          expect(item.state).to eq "ready"
          expect(item.release_date).to eq release_date
          expect(item.workflow_approvers).to \
            include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
          # backup is created
          expect(item.backups.count).to eq 2

          expect(Sys::MailLog.count).to eq 2
          expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
          ActionMailer::Base.deliveries.last.tap do |mail|
            expect(mail.from.first).to eq user1.email
            expect(mail.to.first).to eq cms_user.email
            expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
            expect(mail.body.multipart?).to be_falsey
            expect(mail.body.raw_source).to include(item.name)
          end
        end
      end
    end
  end
end
