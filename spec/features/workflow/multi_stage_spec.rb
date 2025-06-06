require 'spec_helper'

describe "multi_stage", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:layout) { create_cms_layout }
  let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
  let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed') }
  let(:show_path) { article_page_path(site, node, item) }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let(:user1) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user2) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user3) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user4) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user5) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:route_name) { unique_id }
  let(:workflow_comment) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }
  let(:approve_comment3) { unique_id }
  let(:remand_comment3) { unique_id }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "all users must be approved" do
    context "single user at a stage" do
      let!(:route_single_user) do
        create(
          :workflow_route, name: route_name,
          approvers: [
            { "level" => 1, "user_id" => user1.id },
            { "level" => 2, "user_id" => user2.id },
            { "level" => 3, "user_id" => user3.id },
          ],
          required_counts: [ false, false, false, false, false ]
        )
      end

      it do
        expect(item.backups.count).to eq 1

        #
        # admin: send request
        #
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        expect(item.backups.count).to eq 2

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
        login_user user1, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        expect(item.backups.count).to eq 4

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user2.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user2: approve request
        #
        login_user user2, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        expect(item.backups.count).to eq 6

        expect(Sys::MailLog.count).to eq 3
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user3.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user3: approve request, he is the last one
        #
        login_user user3, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment3)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment3, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        expect(item.backups.count).to eq 7

        expect(Sys::MailLog.count).to eq 4
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user3.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item.name)
        end
      end
    end

    context "multiple users at first stage" do
      let!(:route) do
        create(
          :workflow_route, name: route_name,
          approvers: [
            { "level" => 1, "user_id" => user1.id },
            { "level" => 1, "user_id" => user2.id },
            { "level" => 2, "user_id" => user3.id },
          ],
          required_counts: [ false, false, false, false, false ]
        )
      end

      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: '' },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: '' }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.find { |mail| mail.to.first == user1.email }.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user1.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end
        ActionMailer::Base.deliveries.find { |mail| mail.to.first == user2.email }.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user2.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user1: approve request
        #
        login_user user1, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: '' }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: approve request
        #
        login_user user2, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 3
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user3.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user3: approve request, he is the last one
        #
        login_user user3, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment3)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment3, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end

        expect(Sys::MailLog.count).to eq 4
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user3.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item.name)
        end
      end
    end

    context "remand a request" do
      let!(:route_single_user) do
        create(
          :workflow_route, name: route_name,
          approvers: [
            { "level" => 1, "user_id" => user1.id },
            { "level" => 2, "user_id" => user2.id },
            { "level" => 3, "user_id" => user3.id },
          ],
          required_counts: [ false, false, false, false, false ]
        )
      end

      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

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
        login_user user1, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user2.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user2: approve request
        #
        login_user user2, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 3
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user3.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user3: remand request, he is the last one
        #
        login_user user3, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment3
          click_on I18n.t("workflow.buttons.remand")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(remand_comment3)}/)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        item.workflow_approvers[0].tap do |workflow_approver|
          expected = {
            level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[1].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment2, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 3, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REMAND,
            comment: remand_comment3, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end

        expect(Sys::MailLog.count).to eq 4
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user3.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.remand')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(user3.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(remand_comment3)
        end
      end
    end
  end

  context "any users must be approved" do
    context "multiple users at a stage and any of users must be approved" do
      let!(:route) do
        create(
          :workflow_route, name: route_name,
          approvers: [
            { "level" => 1, "user_id" => user1.id },
            { "level" => 1, "user_id" => user2.id },
            { "level" => 2, "user_id" => user3.id },
          ],
          required_counts: [ 1, false, false, false, false ]
        )
      end

      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: '' },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: '' }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_PENDING, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.find{ |mail| mail.to.first == user1.email }.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user1.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end
        ActionMailer::Base.deliveries.find{ |mail| mail.to.first == user2.email }.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user2.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user1: approve request
        #
        login_user user1, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_OTHER_APPROVED, comment: '',
            created: be_within(30.seconds).of(Time.zone.now) }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_REQUEST, comment: ''
          }
          expect(workflow_approver).to eq(expected)
        end

        expect(Sys::MailLog.count).to eq 3
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq user3.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(cms_user.name)
          expect(mail.body.raw_source).to include(item.name)
          expect(mail.body.raw_source).to include(workflow_comment)
        end

        #
        # user3: approve request, user2 no needs to approve request
        #
        login_user user3, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment3)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0, 2]).to include(
          { level: 1, user_id: user1.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment1, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now) },
          { level: 1, user_id: user2.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_OTHER_APPROVED, comment: '',
            created: be_within(30.seconds).of(Time.zone.now) }
        )
        item.workflow_approvers[2].tap do |workflow_approver|
          expected = {
            level: 2, user_id: user3.id, editable: '', state: Workflow::Approver::WORKFLOW_STATE_APPROVE,
            comment: approve_comment3, file_ids: nil, created: be_within(30.seconds).of(Time.zone.now)
          }
          expect(workflow_approver).to include(expected)
        end

        expect(Sys::MailLog.count).to eq 4
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user3.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail.body.raw_source).to include(item.name)
        end
      end
    end
  end
end
