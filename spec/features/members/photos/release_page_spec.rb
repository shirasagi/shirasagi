require 'spec_helper'

describe "member_photos", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :member_node_photo, filename: "photos", name: "photos" }
  let(:item) { create(:member_photo, cur_node: node, state: 'closed') }
  let(:show_path) { member_photo_path site.id, node, item }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let!(:user) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:workflow_comment) { unique_id }
  let(:approve_comment) { unique_id }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "when phote is approved" do
    before { login_cms_user }
    it "#show" do
      visit show_path

      within ".mod-workflow-request" do
        select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")
        click_on I18n.t("workflow.search_approvers.index")
      end
      within "#cboxLoadedContent" do
        expect(page).to have_content(user.long_name)
        click_on user.long_name
      end
      within ".mod-workflow-request" do
        fill_in "workflow[comment]", with: workflow_comment
        click_on I18n.t("workflow.buttons.request")
      end
      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(user.uid)}/)

      item.reload
      expect(item.workflow_user_id).to eq cms_user.id
      expect(item.workflow_state).to eq "request"
      expect(item.state).to eq "closed"
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to include({level: 1, user_id: user.id, editable: '', state: 'request', comment: ''})

      expect(Sys::MailLog.count).to eq 1
      expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
      ActionMailer::Base.deliveries.last.tap do |mail|
        expect(mail.from.first).to eq cms_user.email
        expect(mail.to.first).to eq user.email
        expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item.name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(cms_user.name)
        expect(mail.body.raw_source).to include(item.name)
        expect(mail.body.raw_source).to include(workflow_comment)
      end

      login_user user
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approve_comment
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment)}/)

      item.reload
      expect(item.workflow_state).to eq "approve"
      expect(item.state).to eq "public"
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user.id, editable: '', state: 'approve', comment: approve_comment, file_ids: nil})

      expect(Sys::MailLog.count).to eq 2
      expect(ActionMailer::Base.deliveries.length).to eq Sys::MailLog.count
      ActionMailer::Base.deliveries.last.tap do |mail|
        expect(mail.from.first).to eq user.email
        expect(mail.to.first).to eq cms_user.email
        expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.approve')}]#{item.name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(item.name)
      end
    end
  end
end
