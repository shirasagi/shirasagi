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

  let!(:route) { create(:gws_workflow2_route, group_ids: admin.group_ids) }

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }
  let(:workflow_state) { 'enabled' }
  let!(:form) do
    create(
      :gws_tabular_form, cur_site: site, cur_space: space, cur_user: admin, state: 'publishing', revision: 1,
      workflow_state: workflow_state, approval_state: "with_approval", default_route_id: route.id.to_s, agent_state: "enabled",
      readable_setting_range: "public"
    )
  end
  let!(:column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form, order: 10, required: "required",
      input_type: "single", validation_type: "none", i18n_state: "disabled", unique_state: unique_state)
  end
  let!(:column2) do
    create(
      :gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, order: 20,
      required: "required", export_state: "public")
  end

  let(:column1_value1) { "name-#{unique_id}" }
  let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:attachment) { tmp_ss_file(site: site, contents: attachment_path, basename: 'logo.png') }

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
    file_model = Gws::Tabular::File[form.current_release]
    item_file = file_model.new(cur_site: site, cur_space: space, cur_form: form, cur_user: user1)
    # Basic
    item_file.send("col_#{column1.id}=", column1_value1)
    item_file.send("col_#{column2.id}=", attachment)
    if form.workflow_enabled?
      # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
      item_file.workflow_user = user1
      item_file.workflow_state = 'approve'
      # Gws::Workflow::DestinationState
      item_file.destination_treat_state = 'no_need_to_treat'
      # SS::Release
      item_file.state = 'public'
      item_file.released = Time.zone.now
      item_file.close_date = Time.zone.now + 2.weeks
    end
    item_file.save!
  end

  context "copy as 'unique_state' is disabled" do
    let(:unique_state) { "disabled" }

    it do
      file_model = Gws::Tabular::File[form.current_release]
      expect(file_model.all.count).to eq 1
      item_original = file_model.first

      login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value1
      wait_for_all_turbo_frames
      within ".gws-tabular-file-head" do
        click_on I18n.t("ss.buttons.copy")
      end
      within "form#item-form" do
        # column1 の重複が許可されているので、同じ文字列でも保存に成功する
        fill_in "item[col_#{column1.id}]", with: column1_value1

        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t('ss.notice.copied')
      wait_for_all_turbo_frames

      expect(file_model.all.count).to eq 2
      item_copy = file_model.all.ne(id: item_original.id).first
      # Basic
      expect(item_copy.read_tabular_value(column1)).to eq column1_value1
      item_copy.read_tabular_value(column2).tap do |item_image_value|
        expect(item_image_value).to be_present
        expect(item_image_value.owner_item_id).to eq item_copy.id
        expect(item_image_value.id).not_to eq attachment.id
        expect(item_image_value.name).to eq attachment.name
        expect(item_image_value.filename).to eq attachment.filename
        expect(item_image_value.size).to eq attachment.size
        expect(item_image_value.content_type).to eq attachment.content_type

        public_path = Gws.public_file_path(site, item_image_value)
        expect(::File.exist?(public_path)).to be_falsey
      end
      # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
      expect(item_copy.workflow_user).to be_blank
      expect(item_copy.workflow_agent).to be_blank
      expect(item_copy.workflow_state).to be_blank
      expect(item_copy.workflow_kind).to be_blank
      expect(item_copy.workflow_comment).to be_blank
      expect(item_copy.workflow_pull_up).to be_blank
      expect(item_copy.workflow_on_remand).to be_blank
      expect(item_copy.workflow_approvers).to be_blank
      expect(item_copy.workflow_required_counts).to be_blank
      expect(item_copy.workflow_approver_attachment_uses).to be_blank
      expect(item_copy.workflow_current_level).to be_blank
      expect(item_copy.workflow_current_circulation_level).to eq 0
      expect(item_copy.workflow_circulations).to be_blank
      expect(item_copy.workflow_circulation_attachment_uses).to be_blank
      expect(item_copy.approved).to be_blank
      expect(item_copy.workflow_reminder_sent_at).to be_blank
      expect(item_copy.requested).to be_blank
      # Gws::Workflow::DestinationState
      expect(item_copy.destination_treat_state).to eq "no_need_to_treat"
      # Gws::Workflow::DestinationSetting
      expect(item_copy.destination_group_ids).to be_blank
      expect(item_copy.destination_user_ids).to be_blank
      # SS::Release
      expect(item_copy.state).to eq "closed"
      expect(item_copy.released).to be_blank
      expect(item_copy.release_date).to be_blank
      expect(item_copy.close_date).to be_blank

      attachment.reload
      expect(attachment.owner_item_id).to eq item_original.id
    end
  end

  context "copy as 'unique_state' is enabled" do
    let(:unique_state) { "enabled" }
    let(:column1_value2) { "name-#{unique_id}" }

    it do
      file_model = Gws::Tabular::File[form.current_release]
      expect(file_model.all.count).to eq 1
      item_original = file_model.first

      login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value1
      wait_for_all_turbo_frames
      within ".gws-tabular-file-head" do
        click_on I18n.t("ss.buttons.copy")
      end
      within "form#item-form" do
        # 資産番号の重複は許可されていないので、保存に失敗する
        fill_in "item[col_#{column1.id}]", with: column1_value1

        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      message = I18n.t('mongoid.errors.messages.taken')
      message = I18n.t('errors.format', attribute: column1.name, message: message)
      wait_for_error message

      within "form#item-form" do
        fill_in "item[col_#{column1.id}]", with: column1_value2

        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t('ss.notice.copied')
      wait_for_all_turbo_frames

      expect(file_model.all.count).to eq 2
      item_copy = file_model.all.ne(id: item_original.id).first
      # Basic
      expect(item_copy.read_tabular_value(column1)).to eq column1_value2
      item_copy.read_tabular_value(column2).tap do |item_image_value|
        expect(item_image_value).to be_present
        expect(item_image_value.owner_item_id).to eq item_copy.id
        expect(item_image_value.id).not_to eq attachment.id
        expect(item_image_value.name).to eq attachment.name
        expect(item_image_value.filename).to eq attachment.filename
        expect(item_image_value.size).to eq attachment.size
        expect(item_image_value.content_type).to eq attachment.content_type

        public_path = Gws.public_file_path(site, item_image_value)
        expect(::File.exist?(public_path)).to be_falsey
      end
      # Gws::Addon::Tabular::Approver (Gws::Workflow::Approver, ::Workflow::Approver)
      expect(item_copy.workflow_user).to be_blank
      expect(item_copy.workflow_agent).to be_blank
      expect(item_copy.workflow_state).to be_blank
      expect(item_copy.workflow_kind).to be_blank
      expect(item_copy.workflow_comment).to be_blank
      expect(item_copy.workflow_pull_up).to be_blank
      expect(item_copy.workflow_on_remand).to be_blank
      expect(item_copy.workflow_approvers).to be_blank
      expect(item_copy.workflow_required_counts).to be_blank
      expect(item_copy.workflow_approver_attachment_uses).to be_blank
      expect(item_copy.workflow_current_level).to be_blank
      expect(item_copy.workflow_current_circulation_level).to eq 0
      expect(item_copy.workflow_circulations).to be_blank
      expect(item_copy.workflow_circulation_attachment_uses).to be_blank
      expect(item_copy.approved).to be_blank
      expect(item_copy.workflow_reminder_sent_at).to be_blank
      expect(item_copy.requested).to be_blank
      # Gws::Workflow::DestinationState
      expect(item_copy.destination_treat_state).to eq "no_need_to_treat"
      # Gws::Workflow::DestinationSetting
      expect(item_copy.destination_group_ids).to be_blank
      expect(item_copy.destination_user_ids).to be_blank
      # SS::Release
      expect(item_copy.state).to eq "closed"
      expect(item_copy.released).to be_blank
      expect(item_copy.release_date).to be_blank
      expect(item_copy.close_date).to be_blank

      attachment.reload
      expect(attachment.owner_item_id).to eq item_original.id
    end
  end

  context "when workflow_state is disabled" do
    let(:workflow_state) { 'disabled' }
    let(:unique_state) { "disabled" }


    it do
      file_model = Gws::Tabular::File[form.current_release]
      expect(file_model.all.count).to eq 1
      item_original = file_model.first

      login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
      click_on column1_value1
      wait_for_all_turbo_frames
      within ".gws-tabular-file-head" do
        click_on I18n.t("ss.buttons.copy")
      end
      within "form#item-form" do
        # column1 の重複が許可されているので、同じ文字列でも保存に成功する
        fill_in "item[col_#{column1.id}]", with: column1_value1

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.copied')
      wait_for_all_turbo_frames

      expect(file_model.all.count).to eq 2
      item_copy = file_model.all.ne(id: item_original.id).first
      # Basic
      expect(item_copy.read_tabular_value(column1)).to eq column1_value1
      item_copy.read_tabular_value(column2).tap do |item_image_value|
        expect(item_image_value).to be_present
        expect(item_image_value.owner_item_id).to eq item_copy.id
        expect(item_image_value.id).not_to eq attachment.id
        expect(item_image_value.name).to eq attachment.name
        expect(item_image_value.filename).to eq attachment.filename
        expect(item_image_value.size).to eq attachment.size
        expect(item_image_value.content_type).to eq attachment.content_type

        public_path = Gws.public_file_path(site, item_image_value)
        expect(::File.size(public_path)).to eq item_image_value.size
      end

      attachment.reload
      expect(attachment.owner_item_id).to eq item_original.id
    end
  end
end
