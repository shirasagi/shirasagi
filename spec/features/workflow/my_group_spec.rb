require 'spec_helper'

describe "my_group", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:layout) { create_cms_layout }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let!(:user1) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let!(:user2) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:workflow_comment) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }
  let(:remand_comment1) { unique_id }
  let(:remand_comment2) { unique_id }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "with article/page" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed') }
    let(:show_path) { article_page_path(site, node, item) }

    context "when all users approve request" do
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
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          find("tr[data-id='1,#{user2.id}'] input[type=checkbox]").click
          wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
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
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 2
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq cms_user.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "request"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'request'),
            include(level: 1, user_id: user2.id, state: 'request')
          )
        end

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq(user1.email).or(eq(user2.email))
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(cms_user.name)
          expect(mail_body(mail)).to include(item.name)
          expect(mail_body(mail)).to include(workflow_comment)
        end
        ActionMailer::Base.deliveries.second.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq(user1.email).or(eq(user2.email))
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(cms_user.name)
          expect(mail_body(mail)).to include(item.name)
          expect(mail_body(mail)).to include(workflow_comment)
        end

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq cms_user.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "request_update"
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
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 3
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq user1.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "request"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'approve'),
            include(level: 1, user_id: user2.id, state: 'request')
          )
        end

        expect(Sys::MailLog.count).to eq 2

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq user1.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "approve_update"
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
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment2, file_ids: nil,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        # backup is created because page is in public
        expect(item.backups.count).to eq 4
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq user2.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "approve"
          expect(backup.data["state"]).to eq "public"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'approve'),
            include(level: 1, user_id: user2.id, state: 'approve')
          )
        end

        expect(Sys::MailLog.count).to eq 3
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user2.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(item.name)
        end

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq user2.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "approve_update"
        end
      end
    end

    context "when first user remands request" do
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
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          find("tr[data-id='1,#{user2.id}'] input[type=checkbox]").click
          wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
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
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 2
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq cms_user.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "request"
          expect(backup.data["state"]).to eq "closed"
        end

        expect(Sys::MailLog.count).to eq 2
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.first.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq(user1.email).or(eq(user2.email))
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(cms_user.name)
          expect(mail_body(mail)).to include(item.name)
          expect(mail_body(mail)).to include(workflow_comment)
        end
        ActionMailer::Base.deliveries.second.tap do |mail|
          expect(mail.from.first).to eq cms_user.email
          expect(mail.to.first).to eq(user1.email).or(eq(user2.email))
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(cms_user.name)
          expect(mail_body(mail)).to include(item.name)
          expect(mail_body(mail)).to include(workflow_comment)
        end

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq cms_user.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "request_update"
        end

        #
        # user1: remand request
        #
        login_user user1, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment1
          click_on I18n.t("workflow.buttons.remand")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(remand_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user1.id, editable: '', state: 'remand', comment: remand_comment1,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user2.id, editable: '', state: 'other_remanded', comment: ''})
        expect(item.backups.count).to eq 3
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq user1.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "remand"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'remand'),
            include(level: 1, user_id: user2.id, state: 'other_remanded')
          )
        end

        expect(Sys::MailLog.count).to eq 3
        expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user1.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.remand')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(cms_user.name)
          expect(mail_body(mail)).to include(item.name)
          expect(mail_body(mail)).to include(remand_comment1)
        end

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq user1.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "remand_update"
        end
      end
    end

    context "when first user approves request and then second user remands request" do
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
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          find("tr[data-id='1,#{user2.id}'] input[type=checkbox]").click
          wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
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
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 2
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq cms_user.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "request"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'request'),
            include(level: 1, user_id: user2.id, state: 'request')
          )
        end

        expect(Sys::MailLog.count).to eq 2

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq cms_user.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "request_update"
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
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 3
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq user1.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "request"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'approve'),
            include(level: 1, user_id: user2.id, state: 'request')
          )
        end

        expect(Sys::MailLog.count).to eq 2

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq user1.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "approve_update"
        end

        #
        # user2: remand request
        #
        login_user user2, to: show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment2
          click_on I18n.t("workflow.buttons.remand")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(remand_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        expect(item.workflow_approvers).to \
          include({
            level: 1, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment2,
            created: be_within(30.seconds).of(Time.zone.now)
          })
        expect(item.backups.count).to eq 4
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq user2.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "remand"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'approve'),
            include(level: 1, user_id: user2.id, state: 'remand')
          )
        end

        expect(Sys::MailLog.count).to eq 3
        ActionMailer::Base.deliveries.last.tap do |mail|
          expect(mail.from.first).to eq user2.email
          expect(mail.to.first).to eq cms_user.email
          expect(mail_subject(mail)).to eq "[#{I18n.t('workflow.mail.subject.remand')}]#{item.name} - #{site.name}"
          expect(mail.body.multipart?).to be_falsey
          expect(mail_body(mail)).to include(cms_user.name)
          expect(mail_body(mail)).to include(item.name)
          expect(mail_body(mail)).to include(remand_comment2)
        end

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq user2.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "remand_update"
        end
      end
    end

    context "when request is cancelled" do
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
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          find("tr[data-id='1,#{user2.id}'] input[type=checkbox]").click
          wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
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
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 2
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq cms_user.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "request"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'request'),
            include(level: 1, user_id: user2.id, state: 'request')
          )
        end

        expect(Sys::MailLog.count).to eq 2

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq cms_user.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "request_update"
        end

        #
        # admin: cancel request
        #
        login_cms_user
        visit show_path

        page.accept_confirm do
          within ".mod-workflow-view" do
            click_on I18n.t("workflow.buttons.cancel")
          end
        end

        expect(page).to have_css("#workflow_route", text: I18n.t("workflow.restart_workflow"))
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(I18n.t("workflow.state.cancelled"))}/)

        item.reload
        expect(item.workflow_state).to eq "cancelled"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 3
        item.backups.first.tap do |backup|
          expect(backup.user_id).to eq cms_user.id
          expect(backup.member_id).to be_blank
          expect(backup.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(backup.ref_id).to eq item.id
          expect(backup.ref_class).to eq item.class.name
          expect(backup.data["workflow_state"]).to eq "cancelled"
          expect(backup.data["state"]).to eq "closed"
          expect(backup.data["workflow_approvers"]).to include(
            include(level: 1, user_id: user1.id, state: 'request'),
            include(level: 1, user_id: user2.id, state: 'request')
          )
        end

        expect(Sys::MailLog.count).to eq 2

        History::Log.unscoped.reorder(_id: -1).first.tap do |log|
          expect(log.site_id).to eq site.id
          expect(log.user_id).to eq cms_user.id
          expect(log.ref_coll).to eq Cms::Page.collection_name.to_s
          expect(log.target_class).to eq item.class.name
          expect(log.target_id).to eq item.id.to_s
          expect(log.controller).to eq "workflow/pages"
          expect(log.action).to eq "request_cancel"
        end
      end
    end
  end
end
