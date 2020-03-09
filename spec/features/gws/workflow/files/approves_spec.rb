require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  context "approve file" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let(:sys) { Gws::User.find_by uid: 'sys' }
    let!(:user1) do
      Gws::User.create name: "一般ユーザー1", uid: "user1", email: "user1@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end
    let!(:user2) do
      Gws::User.create name: "一般ユーザー2", uid: "user2", email: "user2@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end
    let!(:user3) do
      Gws::User.create name: "一般ユーザー3", uid: "user3", email: "user3@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end
    let(:item) { create :gws_workflow_file }
    let(:show_path) { gws_workflow_file_path(site, item, state: 'all') }
    let(:workflow_comment) { unique_id }
    let(:remand_comment1) { unique_id }
    let(:remand_comment2) { unique_id }

    before do
      site.canonical_scheme = %w(http https).sample
      site.canonical_domain = "#{unique_id}.example.jp"
      site.save!

      gws_user.notice_workflow_email_user_setting = "notify"
      gws_user.send_notice_mail_addresses = "#{unique_id}@example.jp"
      gws_user.save!

      user1.notice_workflow_email_user_setting = "notify"
      user1.send_notice_mail_addresses = "#{unique_id}@example.jp"
      user1.save!

      ActionMailer::Base.deliveries.clear
    end

    after { ActionMailer::Base.deliveries.clear }

    it do
      login_gws_user
      visit show_path

      #
      # admin: 申請する
      #
      within ".mod-workflow-request" do
        select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")
        click_on I18n.t("workflow.search_approvers.index")
      end
      wait_for_cbox do
        expect(page).to have_content(user1.long_name)
        find("tr[data-id=\"1,#{user1.id}\"] input[type=checkbox]").click
        find("tr[data-id=\"1,#{user2.id}\"] input[type=checkbox]").click
        click_on I18n.t("workflow.search_approvers.select")
      end
      within ".mod-workflow-request" do
        fill_in "workflow[comment]", with: workflow_comment
        click_on I18n.t("workflow.buttons.request")
      end
      expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

      expect(SS::Notification.count).to eq 2
      notice1 = SS::Notification.all.reorder(created: -1).first
      expect(notice1.group_id).to eq site.id
      expect(notice1.member_ids).to eq [ user1.id ]
      expect(notice1.user_id).to eq gws_user.id
      expect(notice1.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
      expect(notice1.text).to be_blank
      expect(notice1.html).to be_blank
      expect(notice1.format).to eq "text"
      expect(notice1.seen).to be_blank
      expect(notice1.state).to eq "public"
      expect(notice1.send_date).to be_present
      expect(notice1.url).to eq "/.g#{site.id}/workflow/files/all/#{item.id}"
      expect(notice1.reply_module).to be_blank
      expect(notice1.reply_model).to be_blank
      expect(notice1.reply_item_id).to be_blank
      SS::Notification.all.reorder(created: -1).second.tap do |notice|
        expect(notice.group_id).to eq site.id
        expect(notice.member_ids).to eq [ user2.id ]
        expect(notice.user_id).to eq gws_user.id
        expect(notice.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(notice.text).to be_blank
        expect(notice.html).to be_blank
        expect(notice.format).to eq "text"
        expect(notice.seen).to be_blank
        expect(notice.state).to eq "public"
        expect(notice.send_date).to be_present
        expect(notice.url).to eq "/.g#{site.id}/workflow/files/all/#{item.id}"
        expect(notice.reply_module).to be_blank
        expect(notice.reply_model).to be_blank
        expect(notice.reply_item_id).to be_blank
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.last.tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        expect(mail.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice1.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)
      end

      #
      # user1: 申請を承認する
      #
      login_user user1
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment1
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(remand_comment1)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: remand_comment1, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

      expect(SS::Notification.count).to eq 2
      expect(ActionMailer::Base.deliveries.length).to eq 1

      #
      # user2: 申請を承認する
      #
      login_user user2
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment2
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(remand_comment2)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: remand_comment1, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user2.id, editable: '', state: 'approve', comment: remand_comment2, file_ids: nil})

      expect(SS::Notification.count).to eq 3
      notice3 = SS::Notification.all.reorder(created: -1).first
      expect(notice3.group_id).to eq site.id
      expect(notice3.member_ids).to eq [ gws_user.id ]
      expect(notice3.user_id).to eq user2.id
      expect(notice3.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
      expect(notice3.text).to be_blank
      expect(notice3.html).to be_blank
      expect(notice3.format).to eq "text"
      expect(notice3.seen).to be_blank
      expect(notice3.state).to eq "public"
      expect(notice3.send_date).to be_present
      expect(notice3.url).to eq "/.g#{site.id}/workflow/files/all/#{item.id}"
      expect(notice3.reply_module).to be_blank
      expect(notice3.reply_model).to be_blank
      expect(notice3.reply_item_id).to be_blank

      expect(ActionMailer::Base.deliveries.length).to eq 2
      ActionMailer::Base.deliveries.last.tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq gws_user.send_notice_mail_addresses.first
        expect(mail.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notice3.id}"
        expect(mail.decoded.to_s).to include(mail.subject, url)
      end
    end
  end
end
