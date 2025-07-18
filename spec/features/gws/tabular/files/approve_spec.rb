require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:permissions) { %w(use_gws_tabular read_gws_tabular_files edit_gws_tabular_files) }
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }
  let!(:user2) { create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }
  let!(:user3) { create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

  let!(:route) do
    create(
      :gws_workflow2_route, name: unique_id, group_ids: admin.group_ids,
      approvers: [
        { "level" => 1, "user_type" => Gws::User.name, "user_id" => user2.id, "editable" => 1 },
      ],
      required_counts: [ 1, false, false, false, false ],
      approver_attachment_uses: %w(enabled disabled disabled disabled disabled),
      circulations: [
        { "level" => 1, "user_type" => Gws::User.name, "user_id" => user3.id },
      ],
      circulation_attachment_uses: %w(enabled disabled disabled)
    )
  end

  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: admin, state: "public", readable_setting_range: "public" }
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
      input_type: "single", validation_type: "none", i18n_state: "disabled")
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
  end

  context "crud with workflow" do
    let(:column1_value1) { "name-#{unique_id}" }
    let(:column1_value2) { "name-#{unique_id}" }
    let(:workflow_comment1) { "workflow_comment-#{unique_id}" }
    let(:approve_comment1) { "approve_comment-#{unique_id}" }
    let(:circulation_comment1) { "circulation_comment-#{unique_id}" }

    it do
      expect(SS::Notification.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0

      #
      # first, user1 operates
      #
      login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[col_#{column1.id}]", with: column1_value1

        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_turbo_frames

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          # basic
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value1
          # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
          expect(file.workflow_user).to be_blank
          expect(file.workflow_agent).to be_blank
          expect(file.workflow_state).to be_blank
          expect(file.workflow_kind).to be_blank
          expect(file.workflow_comment).to be_blank
          expect(file.workflow_pull_up).to be_blank
          expect(file.workflow_on_remand).to be_blank
          expect(file.workflow_approvers).to be_blank
          expect(file.workflow_required_counts).to be_blank
          expect(file.workflow_approver_attachment_uses).to be_blank
          expect(file.workflow_current_level).to be_blank
          expect(file.workflow_current_circulation_level).to eq 0
          expect(file.workflow_circulations).to be_blank
          expect(file.workflow_circulation_attachment_uses).to be_blank
          expect(file.approved).to be_blank
          expect(file.workflow_reminder_sent_at).to be_blank
          expect(file.requested).to be_blank
        end
      end

      expect(SS::Notification.count).to eq 0
      expect(ActionMailer::Base.deliveries.length).to eq 0

      #
      # 申請
      #
      within ".mod-workflow-request" do
        fill_in "item[workflow_comment]", with: workflow_comment1
        click_on I18n.t("workflow.buttons.request")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.requested")
      wait_for_all_turbo_frames

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)
      end

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          # basic
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value1
          # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
          expect(file.workflow_user).to eq user1
          expect(file.workflow_agent).to be_blank
          expect(file.workflow_state).to eq "request"
          expect(file.workflow_kind).to be_blank
          expect(file.workflow_comment).to eq workflow_comment1
          expect(file.workflow_pull_up).to be_blank
          expect(file.workflow_on_remand).to be_blank
          expect(file.workflow_approvers.count).to eq 1
          expect(file.workflow_approvers).to include(
            { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'request', comment: '', editable: 1 }
          )
          expect(file.workflow_required_counts).to eq [ 1, false, false, false, false ]
          expect(file.workflow_approver_attachment_uses).to eq %w(enabled disabled disabled disabled disabled)
          expect(file.workflow_current_level).to eq 1
          expect(file.workflow_current_circulation_level).to eq 0
          expect(file.workflow_circulations.count).to eq 1
          expect(file.workflow_circulations).to include(
            { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'pending', comment: '' }
          )
          expect(file.workflow_circulation_attachment_uses).to eq %w(enabled disabled disabled)
          expect(file.approved).to be_blank
          expect(file.workflow_reminder_sent_at).to be_blank
          expect(file.requested.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
        end
      end

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).to_a.tap do |notifications|
        notifications[0].tap do |notification|
          subject = I18n.t("gws_notification.gws/tabular/file.request", form: form.i18n_name, name: column1_value1)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user1.id
          expect(notification.member_ids).to eq [user2.id]
          file = Gws::Tabular::File[form.current_release].then { |file_model| file_model.first }
          path = gws_tabular_file_path(site: site, space: space, form: form, view: "-", id: file)
          expect(notification.url).to eq path
        end
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.last.tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user2.send_notice_mail_addresses.first
        subject = I18n.t("gws_notification.gws/tabular/file.request", form: form.i18n_name, name: column1_value1)
        expect(mail.subject).to eq subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/"
        expect(mail.decoded.to_s).to include(mail.subject, url)
        expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
      end

      #
      # 承認者が承認の際に編集
      #
      login_user user2, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value1
      wait_for_all_turbo_frames
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[col_#{column1.id}]", with: column1_value2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_all_turbo_frames

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          # basic
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value2
        end
      end

      #
      # 承認
      #
      visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value2
      wait_for_all_turbo_frames
      within ".mod-workflow-approve" do
        fill_in "item[comment]", with: approve_comment1
        wait_cbox_open { click_on I18n.t("workflow.links.approver_file_upload") }
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        wait_cbox_close { click_on I18n.t("ss.buttons.attach") }
      end
      within ".mod-workflow-approve" do
        click_on I18n.t("workflow.buttons.approve")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.approved")
      wait_for_all_turbo_frames

      expect(SS::File.all.where(model: "workflow/approver_file").count).to eq 1
      file1 = SS::File.all.where(model: "workflow/approver_file").order_by(id: -1).first
      expect(file1.name).to eq "logo.png"
      expect(file1.filename).to eq "logo.png"
      expect(file1.site_id).to be_blank
      expect(file1.model).to eq "workflow/approver_file"
      expect(file1.owner_item_id).to be_present
      expect(file1.owner_item_type).to eq Gws::Tabular::File[form.current_release].name

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)

        within ".workflow_approvers" do
          within "[data-level='1'][data-approver-id='#{user2.id}']" do
            open_dialog "chat"
          end
        end
      end
      within_dialog do
        expect(page).to have_css(".approver-comment", text: approve_comment1)
        expect(page).to have_css(".file-view[data-file-id='#{file1.id}']", text: file1.humanized_name)
        wait_cbox_close { click_on "cancel" }
      end

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          # basic
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value2
          # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
          expect(file.workflow_user).to eq user1
          expect(file.workflow_agent).to be_blank
          expect(file.workflow_state).to eq "approve"
          expect(file.workflow_kind).to be_blank
          expect(file.workflow_comment).to eq workflow_comment1
          expect(file.workflow_pull_up).to be_blank
          expect(file.workflow_on_remand).to be_blank
          expect(file.workflow_approvers.count).to eq 1
          expect(file.workflow_approvers).to include(
            { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment1, editable: 1,
              file_ids: [ file1.id ], created: be_within(5.minutes).of(Time.zone.now) }
          )
          expect(file.workflow_required_counts).to eq [ 1, false, false, false, false ]
          expect(file.workflow_approver_attachment_uses).to eq %w(enabled disabled disabled disabled disabled)
          expect(file.workflow_current_level).to be_blank
          expect(file.workflow_current_circulation_level).to eq 1
          expect(file.workflow_circulations.count).to eq 1
          expect(file.workflow_circulations).to include(
            { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'unseen', comment: '' }
          )
          expect(file.workflow_circulation_attachment_uses).to eq %w(enabled disabled disabled)
          expect(file.approved.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
          expect(file.workflow_reminder_sent_at).to be_blank
          expect(file.requested.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
        end
      end

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).to_a.tap do |notifications|
        notifications[0].tap do |notification|
          subject = I18n.t(
            "gws_notification.gws/tabular/file.circular", form: form.i18n_name, name: column1_value2)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user1.id
          expect(notification.member_ids).to eq [user3.id]
          file = Gws::Tabular::File[form.current_release].then { |file_model| file_model.first }
          path = gws_tabular_file_path(site: site, space: space, form: form, view: "-", id: file)
          expect(notification.url).to eq path
        end
        notifications[1].tap do |notification|
          subject = I18n.t(
            "gws_notification.gws/tabular/file.approve", form: form.i18n_name, name: column1_value2)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user2.id
          expect(notification.member_ids).to eq [user1.id]
          file = Gws::Tabular::File[form.current_release].then { |file_model| file_model.first }
          path = gws_tabular_file_path(site: site, space: space, form: form, view: "-", id: file)
          expect(notification.url).to eq path
        end
      end

      expect(ActionMailer::Base.deliveries.length).to eq 3
      ActionMailer::Base.deliveries[-1].tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user3.send_notice_mail_addresses.first
        subject = I18n.t(
          "gws_notification.gws/tabular/file.circular", form: form.i18n_name, name: column1_value2)
        expect(mail.subject).to eq subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/"
        expect(mail.decoded.to_s).to include(mail.subject, url)
        expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
      end
      ActionMailer::Base.deliveries[-2].tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        subject = I18n.t(
          "gws_notification.gws/tabular/file.approve", form: form.i18n_name, name: column1_value2)
        expect(mail.subject).to eq subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/"
        expect(mail.decoded.to_s).to include(mail.subject, url)
        expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
      end

      #
      # 確認する（回覧）
      #
      login_user user3, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value2
      wait_for_all_turbo_frames
      within ".mod-workflow-circulation" do
        fill_in "item[comment]", with: circulation_comment1
        wait_cbox_open { click_on I18n.t("workflow.links.approver_file_upload") }
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        wait_cbox_close { click_on I18n.t("ss.buttons.attach") }
      end
      within ".mod-workflow-circulation" do
        click_on I18n.t("workflow.links.set_seen")
      end
      wait_for_notice I18n.t("gws/workflow2.notice.seen")
      wait_for_all_turbo_frames

      expect(SS::File.all.where(model: "workflow/approver_file").count).to eq 2
      file2 = SS::File.all.where(model: "workflow/approver_file").order_by(id: -1).first
      expect(file2.name).to eq "logo.png"
      expect(file2.filename).to eq "logo.png"
      expect(file2.site_id).to be_blank
      expect(file2.model).to eq "workflow/approver_file"
      expect(file2.owner_item_id).to be_present
      expect(file2.owner_item_type).to eq Gws::Tabular::File[form.current_release].name

      within ".mod-workflow-view" do
        expect(page).to have_css(".workflow_state", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".workflow_comment", text: workflow_comment1)

        within ".workflow_circulations" do
          within "[data-level='1'][data-circulation-id='#{user3.id}']" do
            open_dialog "chat"
          end
        end
      end
      within_dialog do
        expect(page).to have_css(".approver-comment", text: circulation_comment1)
        expect(page).to have_css(".file-view[data-file-id='#{file2.id}']", text: file2.humanized_name)
        wait_cbox_close { click_on "cancel" }
      end

      Gws::Tabular::File[form.current_release].tap do |file_model|
        expect(file_model.all.count).to eq 1
        file_model.all.first.tap do |file|
          # basic
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq user1.id
          expect(file.space_id).to eq space.id
          expect(file.form_id).to eq form.id
          expect(file.read_tabular_value(column1)).to eq column1_value2
          # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
          expect(file.workflow_user).to eq user1
          expect(file.workflow_agent).to be_blank
          expect(file.workflow_state).to eq "approve"
          expect(file.workflow_kind).to be_blank
          expect(file.workflow_comment).to eq workflow_comment1
          expect(file.workflow_pull_up).to be_blank
          expect(file.workflow_on_remand).to be_blank
          expect(file.workflow_approvers.count).to eq 1
          expect(file.workflow_approvers).to include(
            { level: 1, user_type: Gws::User.name, user_id: user2.id, state: 'approve', comment: approve_comment1, editable: 1,
              file_ids: [ file1.id ], created: be_within(5.minutes).of(Time.zone.now) }
          )
          expect(file.workflow_required_counts).to eq [ 1, false, false, false, false ]
          expect(file.workflow_approver_attachment_uses).to eq %w(enabled disabled disabled disabled disabled)
          expect(file.workflow_current_level).to be_blank
          expect(file.workflow_current_circulation_level).to eq 1
          expect(file.workflow_circulations.count).to eq 1
          expect(file.workflow_circulations).to include(
            { level: 1, user_type: Gws::User.name, user_id: user3.id, state: 'seen', comment: circulation_comment1,
              file_ids: [ file2.id ] }
          )
          expect(file.workflow_circulation_attachment_uses).to eq %w(enabled disabled disabled)
          expect(file.approved.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
          expect(file.workflow_reminder_sent_at).to be_blank
          expect(file.requested.in_time_zone).to be_within(5.minutes).of(Time.zone.now)
        end
      end

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(id: -1).to_a.tap do |notifications|
        notifications[0].tap do |notification|
          subject = I18n.t(
            "gws_notification.gws/tabular/file.comment", form: form.i18n_name, name: column1_value2)
          expect(notification.subject).to eq subject
          expect(notification.text).to be_blank
          expect(notification.html).to be_blank
          expect(notification.user_id).to eq user3.id
          expect(notification.member_ids).to eq [user1.id]
          file = Gws::Tabular::File[form.current_release].then { |file_model| file_model.first }
          path = gws_tabular_file_path(site: site, space: space, form: form, view: "-", id: file)
          expect(notification.url).to eq path
        end
      end

      expect(ActionMailer::Base.deliveries.length).to eq 4
      ActionMailer::Base.deliveries[-1].tap do |mail|
        expect(mail.from.first).to eq site.sender_address
        expect(mail.bcc.first).to eq user1.send_notice_mail_addresses.first
        subject = I18n.t(
          "gws_notification.gws/tabular/file.comment", form: form.i18n_name, name: column1_value2)
        expect(mail.subject).to eq subject
        url = "#{site.canonical_scheme}://#{site.canonical_domain}/.g#{site.id}/memo/notices/"
        expect(mail.decoded.to_s).to include(mail.subject, url)
        expect(mail.message_id).to end_with("@#{site.canonical_domain}.mail")
      end
    end
  end
end
