require 'spec_helper'

describe Gws::Workflow2::RequestService, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:minimum_role) do
    permissions = %w(use_gws_workflow2 read_private_gws_workflow2_files edit_private_gws_workflow2_files)
    create(:gws_role, cur_site: site, permissions: permissions)
  end
  let!(:user1) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [ minimum_role.id ]) }

  let!(:route) do
    create(
      :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_type" => "superior", "user_id" => "superior", "editable" => 1, "alternatable" => 1 },
      ],
      required_counts: Array.new(Gws::Workflow2::Route::MAX_APPROVERS) { false }
    )
  end

  let!(:form) do
    create(
      :gws_workflow2_form_application, cur_site: site, default_route_id: route.id,
      readable_setting_range: "public", state: "public")
  end
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }

  before do
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    admin.groups.site(site).each do |group|
      group.update!(superior_user_ids: [ admin.id ])
    end

    admin.notice_workflow_user_setting = "notify"
    admin.notice_workflow_email_user_setting = "notify"
    admin.send_notice_mail_addresses = "#{unique_id}@example.jp"
    admin.save!

    ActionMailer::Base.deliveries.clear
  end

  after { ActionMailer::Base.deliveries.clear }

  context "usual case" do
    let(:workflow_comment) { unique_id }
    let!(:file) do
      create(
        :gws_workflow2_file, cur_site: site, cur_user: user1, form: form, column_values: [ column1.serialize_value(unique_id) ])
    end

    it do
      cur_group = user1.groups.site(site).first
      resolver = Gws::Workflow2::ApproverResolver.new(
        cur_site: site, cur_user: user1, cur_group: cur_group, route: route, item: file)
      # resolver.attributes = params.require(:item).permit(*Gws::Workflow::ApproverResolver::PERMIT_PARAMS)
      resolver.resolve

      service = Gws::Workflow2::RequestService.new(
        cur_site: site, cur_user: user1, cur_group: cur_group, route_id: route.id, route: route,
        item: file, ref: "/.g#{site.id}/workflow/files/all/#{file.id}")
      service.attributes = {
        workflow_agent_type: nil, workflow_user_id: user1.id, workflow_comment: workflow_comment
      }
      result = service.call
      expect(result).to be_truthy

      Gws::Workflow2::File.find(file.id).tap do |after_file|
        expect(after_file.workflow_user_id).to eq user1.id
        expect(after_file.workflow_agent_id).to be_blank
        expect(after_file.workflow_state).to eq "request"
        expect(after_file.workflow_comment).to eq workflow_comment
        expect(after_file.workflow_approvers.count).to eq 1
        expect(after_file.workflow_approvers).to include(
          { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' }
        )
        expect(after_file.workflow_required_counts).to eq Array.new(Gws::Workflow2::Route::MAX_APPROVERS) { false }
        expect(after_file.workflow_circulations).to be_blank
      end

      expect(SS::Notification.count).to eq 1
      notification = SS::Notification.order_by(id: -1).first
      expect(notification.user_id).to eq user1.id
      expect(notification.member_ids).to eq [ admin.id ]
      subject = I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
      expect(notification.subject).to eq subject

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq admin.send_notice_mail_addresses.first
        expect(mail_subject(mail)).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file.name)
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/#{notification.id}"
        expect(mail_body(mail)).to include(mail_subject(mail), url)
        expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
      end
    end
  end

  context "file is already requested" do
    let(:workflow_comment) { unique_id }
    let!(:file) do
      create(
        :gws_workflow_file, cur_site: site, cur_user: user1, form: form, column_values: [ column1.serialize_value(unique_id) ],
        workflow_user_id: user1.id, workflow_state: "request", workflow_comment: workflow_comment,
        workflow_approvers: [
          { level: 1, user_type: "superior", user_id: admin.id, state: 'request', editable: 1, comment: '' }
        ],
        workflow_required_counts: Array.new(Gws::Workflow::Route::MAX_APPROVERS) { false }
      )
    end

    it do
      cur_group = user1.groups.site(site).first
      resolver = Gws::Workflow2::ApproverResolver.new(
        cur_site: site, cur_user: user1, cur_group: cur_group, route: route, item: file)
      resolver.resolve

      service = Gws::Workflow2::RequestService.new(
        cur_site: site, cur_user: user1, cur_group: cur_group, route_id: route.id, route: route,
        item: file, ref: "/.g#{site.id}/workflow/files/all/#{file.id}")
      service.attributes = {
        workflow_agent_type: nil, workflow_user_id: user1.id, workflow_comment: workflow_comment
      }
      result = service.call
      expect(result).to be_falsey
      expect(file.errors[:base]).to have(1).items
      expect(file.errors[:base]).to include(I18n.t("errors.messages.unable_to_request_application"))

      expect(SS::Notification.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end
end
