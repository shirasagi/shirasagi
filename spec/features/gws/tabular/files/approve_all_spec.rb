require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:now) { Time.zone.now.change(sec: 0) }
  # 投稿者
  let!(:permissions_creator) { %w(use_gws_tabular read_gws_tabular_files edit_gws_tabular_files) }
  let!(:role_creator) { create(:gws_role, cur_site: site, permissions: permissions_creator) }
  let!(:user1) do
    create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role_creator.id ]
  end
  # 会計担当者（業務管理者、承認者）
  let(:permissions_accountant) { %w(use_gws_tabular read_gws_tabular_files) }
  let!(:role_accountant) { create(:gws_role, cur_site: site, permissions: permissions_accountant) }
  let!(:user2) do
    create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role_accountant.id ]
  end

  let!(:route) do
    create(
      :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_type" => user2.class.name, "user_id" => user2.id, "editable" => 1 },
      ],
      required_counts: [ false, false, false, false, false ],
      approver_attachment_uses: %w(enabled disabled disabled disabled disabled)
    )
  end

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, cur_user: admin, state: 'publishing', revision: 1,
      workflow_state: 'enabled', approval_state: "with_approval", default_route_id: route.id.to_s, agent_state: "enabled",
      readable_setting_range: "public"
    )
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10, required: "required",
      input_type: "single", i18n_default_value_translations: nil, validation_type: "none", i18n_state: "disabled")
  end
  let!(:column2) do
    create(
      :gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, order: 20,
      required: "required", export_state: "public")
  end

  before do
    site.path_id = unique_id
    site.canonical_scheme = %w(http https).sample
    site.canonical_domain = "#{unique_id}.example.jp"
    site.save!

    ActionMailer::Base.deliveries.clear

    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    form.reload
  end

  after { ActionMailer::Base.deliveries.clear }

  context "approve all" do
    let(:column1_value1) { "name-#{unique_id}" }
    let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:attachment) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }

    let(:workflow_comment1) { "workflow_comment-#{unique_id}" }
    let(:approve_comment1) { "approve_comment-#{unique_id}" }
    let(:circulation_comment1) { "circulation_comment-#{unique_id}" }
    let!(:file_model) { Gws::Tabular::File[form.current_release] }
    let!(:file_item) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form,
        "col_#{column1.id}" => column1_value1,
        "col_#{column2.id}" => attachment,
        workflow_user: user1, workflow_state: 'request', workflow_comment: workflow_comment1,
        workflow_approvers: [
          { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '', editable: 1 }
        ],
        workflow_required_counts: [ false, false, false, false, false ],
        workflow_approver_attachment_uses: %w(enabled disabled disabled disabled disabled),
        requested: Time.zone.now, destination_treat_state: "no_need_to_treat",
        state: "closed"
      )
    end

    it do
      expect(SS::Notification.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0

      #
      # 一括承認
      #
      login_user user2, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-', s: { act: "approver" })
      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action" do
        open_dialog I18n.t("workflow.buttons.approve")
      end
      wait_for_event_fired "gws:tabular:approve-all" do
        within_dialog do
          within "form#workflow-inspection" do
            fill_in "comment", with: approve_comment1
            click_on I18n.t("workflow.buttons.approve")
          end
        end
      end
      within ".list-item[data-id='#{file_item.id}']" do
        expect(page).to have_css(".ss-ajax-success", text: I18n.t("gws/workflow2.notice.approved"))
      end

      file_item.reload
      # Basic
      expect(file_item.read_tabular_value(column1)).to eq column1_value1
      file_item.read_tabular_value(column2).tap do |item_image_value|
        expect(item_image_value).to be_present
        expect(item_image_value.owner_item_id).to eq file_item.id
        expect(item_image_value.id).to eq attachment.id
        expect(item_image_value.name).to eq attachment.name
        expect(item_image_value.filename).to eq attachment.filename
        expect(item_image_value.size).to eq attachment.size
        expect(item_image_value.content_type).to eq attachment.content_type

        public_path = Gws.public_file_path(site, item_image_value)
        expect(::File.size(public_path)).to eq attachment.size
      end
      # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
      expect(file_item.workflow_user).to eq user1
      expect(file_item.workflow_agent).to be_blank
      expect(file_item.workflow_state).to eq 'approve'
      expect(file_item.workflow_kind).to be_blank
      expect(file_item.workflow_comment).to eq workflow_comment1
      expect(file_item.workflow_pull_up).to be_blank
      expect(file_item.workflow_on_remand).to be_blank
      expect(file_item.workflow_approvers.count).to eq 1
      expect(file_item.workflow_approvers).to include(
        { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment1, editable: 1,
          file_ids: nil, created: be_within(5.minutes).of(Time.zone.now) }
      )
      expect(file_item.workflow_required_counts).to eq [ false, false, false, false, false ]
      expect(file_item.workflow_approver_attachment_uses).to eq %w(enabled disabled disabled disabled disabled)
      expect(file_item.workflow_current_level).to be_blank
      expect(file_item.workflow_current_circulation_level).to eq 0
      expect(file_item.workflow_circulations).to be_blank
      expect(file_item.workflow_circulation_attachment_uses).to be_blank
      expect(file_item.approved.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
      expect(file_item.workflow_reminder_sent_at).to be_blank
      expect(file_item.requested.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
      # Gws::Workflow::DestinationState / Gws::Workflow::DestinationSetting
      expect(file_item.destination_treat_state).to eq "no_need_to_treat"
      expect(file_item.destination_group_ids).to be_blank
      expect(file_item.destination_user_ids).to be_blank
      # SS::Release
      expect(file_item.state).to eq "public"
      expect(file_item.released.in_time_zone).to be_within(5.minutes).of(file_item.approved.in_time_zone)
      expect(file_item.release_date).to be_blank
      expect(file_item.close_date).to be_blank

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).to_a.tap do |notifications|
        notifications[0].tap do |notification|
          subject = I18n.t(
            "gws_notification.gws/tabular/file.approve", form: form.i18n_name, name: column1_value1)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user2.id
          expect(notification.member_ids).to eq [user1.id]
          path = gws_tabular_file_path(site: site, space: space, form: form, view: '-', id: file_item)
          expect(notification.url).to eq path
        end
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries[-1].tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        subject = I18n.t(
          "gws_notification.gws/tabular/file.approve", form: form.i18n_name, name: column1_value1)
        expect(mail_subject(mail)).to eq subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/"
        expect(mail_body(mail)).to include(mail_subject(mail), url)
        expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
      end

      # （誤って）承認済みの投稿を選択して承認を行った場合、（エラーにならず）承認済メッセージがでて、投稿者へ掲載開始通知が発信される
      login_user user2, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-', s: { act: "approver" })
      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action" do
        open_dialog I18n.t("workflow.buttons.approve")
      end
      wait_for_event_fired "gws:tabular:approve-all" do
        within_dialog do
          within "form#workflow-inspection" do
            fill_in "comment", with: approve_comment1
            click_on I18n.t("workflow.buttons.approve")
          end
        end
      end
      within ".list-item[data-id='#{file_item.id}']" do
        error = I18n.t("errors.messages.workflow_application_is_not_requested")
        expect(page).to have_css(".ss-ajax-failure", text: error)
      end

      # No notifications are sent
      expect(SS::Notification.count).to eq 1
      expect(ActionMailer::Base.deliveries.length).to eq 1
    end
  end

  context "不備がある投稿の一括承認" do
    let(:column1_value1) { "name-#{unique_id}" }
    let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:attachment) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }
    let(:workflow_comment1) { "workflow_comment-#{unique_id}" }
    let(:approve_comment1) { "approve_comment-#{unique_id}" }
    let(:circulation_comment1) { "circulation_comment-#{unique_id}" }
    let!(:file_model) { Gws::Tabular::File[form.current_release] }
    let!(:file_item) do
      file_model.create!(
        cur_user: user1, cur_site: site, cur_space: space, cur_form: form,
        "col_#{column1.id}" => column1_value1,
        "col_#{column2.id}" => attachment,
        workflow_user: user1, workflow_state: 'request', workflow_comment: workflow_comment1,
        workflow_approvers: [
          { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '', editable: 1 }
        ],
        workflow_required_counts: [ false, false, false, false, false ],
        workflow_approver_attachment_uses: %w(enabled disabled disabled disabled disabled),
        requested: Time.zone.now, destination_treat_state: "no_need_to_treat",
        state: "closed"
      )
    end

    before do
      # required な項目をクリアすることで、不備がある投稿をシミュレーションする
      file_item.unset("col_#{column1.id}")
      expect(file_item.send("col_#{column1.id}")).to be_blank
    end

    it do
      expect(SS::Notification.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0

      #
      # 一括承認
      #
      login_user user2, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-', s: { act: "approver" })
      wait_for_event_fired("ss:checked-all-list-items") do
        find('.list-head input[type="checkbox"]').set(true)
      end
      within ".list-head-action" do
        open_dialog I18n.t("workflow.buttons.approve")
      end
      wait_for_event_fired "gws:tabular:approve-all" do
        within_dialog do
          within "form#workflow-inspection" do
            fill_in "comment", with: approve_comment1
            click_on I18n.t("workflow.buttons.approve")
          end
        end
      end
      within ".list-item[data-id='#{file_item.id}']" do
        error = I18n.t("errors.messages.blank")
        error = I18n.t("errors.format", attribute: column1.name, message: error)
        expect(page).to have_css(".ss-ajax-failure", text: error)
      end

      file_item.reload
      # Basic
      expect(file_item.read_tabular_value(column1)).to be_blank
      file_item.read_tabular_value(column2).tap do |item_image_value|
        expect(item_image_value).to be_present
        expect(item_image_value.owner_item_id).to eq file_item.id
        expect(item_image_value.id).to eq attachment.id
        expect(item_image_value.name).to eq attachment.name
        expect(item_image_value.filename).to eq attachment.filename
        expect(item_image_value.size).to eq attachment.size
        expect(item_image_value.content_type).to eq attachment.content_type

        public_path = Gws.public_file_path(site, item_image_value)
        expect(::File.exist?(public_path)).to be_falsey
      end
      # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
      expect(file_item.workflow_user).to eq user1
      expect(file_item.workflow_agent).to be_blank
      expect(file_item.workflow_state).to eq 'request'
      expect(file_item.workflow_kind).to be_blank
      expect(file_item.workflow_comment).to eq workflow_comment1
      expect(file_item.workflow_pull_up).to be_blank
      expect(file_item.workflow_on_remand).to be_blank
      expect(file_item.workflow_approvers.count).to eq 1
      expect(file_item.workflow_approvers).to include(
        { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '', editable: 1 }
      )
      expect(file_item.workflow_required_counts).to eq [ false, false, false, false, false ]
      expect(file_item.workflow_approver_attachment_uses).to eq %w(enabled disabled disabled disabled disabled)
      expect(file_item.workflow_current_level).to eq 1
      expect(file_item.workflow_current_circulation_level).to eq 0
      expect(file_item.workflow_circulations).to be_blank
      expect(file_item.workflow_circulation_attachment_uses).to be_blank
      expect(file_item.approved).to be_blank
      expect(file_item.workflow_reminder_sent_at).to be_blank
      expect(file_item.requested.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
      # Gws::Workflow::DestinationState / Gws::Workflow::DestinationSetting
      expect(file_item.destination_treat_state).to eq "no_need_to_treat"
      expect(file_item.destination_group_ids).to be_blank
      expect(file_item.destination_user_ids).to be_blank
      # SS::Release
      expect(file_item.state).to eq "closed"
      expect(file_item.released).to be_blank
      expect(file_item.release_date).to be_blank
      expect(file_item.close_date).to be_blank

      # No notifications are sent
      expect(SS::Notification.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end

  context "no items are selected" do
    it do
      login_user user2, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-', s: { act: "approver" })
      # 「承認」ボタンには "disabled" がセットされていてクリックできないので、強制的に "disabled" を解除する
      page.execute_script("document.querySelector(\"[name='approve_all']\").removeAttribute('disabled')")
      # 未選択の状態で「承認」ボタンをクリックすると、「選択してください」エラーが表示されるはず
      page.accept_alert(I18n.t("helpers.select.prompt")) do
        within ".list-head-action" do
          click_on I18n.t("workflow.buttons.approve")
        end
      end
    end
  end
end
