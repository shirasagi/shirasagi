require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:now) { Time.zone.now.change(sec: 0) }
  # 投稿者
  let!(:permissions_super_reader) { %w(use_gws_tabular read_gws_tabular_files download_gws_tabular_files) }
  let!(:role_super_reader) { create(:gws_role, cur_site: site, permissions: permissions_super_reader) }
  let!(:user1) do
    create :gws_user, :gws_tabular_notice, group_ids: admin.group_ids, gws_role_ids: [ role_super_reader.id ]
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
      input_type: "single", validation_type: "none", i18n_state: "disabled", unique_state: "disabled")
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

  context "download all" do
    let(:encoding) { %w(UTF-8 Shift_JIS).sample }

    context "with csv" do
      it do
        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.all.count).to eq 1
        item_original = file_model.first

        login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
        click_on I18n.t("ss.links.download")

        wait_for_download("gws_tabular_files", extname: ".csv") do
          within "form#item-form" do
            choose "item[format]", option: "csv"
            choose "item[encoding]", option: encoding

            click_on I18n.t("ss.buttons.download")
          end
        end

        expect(File.size(downloaded_path)).to be > 0
        SS::Csv.open(downloaded_path) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[column1.name]).to eq column1_value1
            expect(csv_row[column2.name]).to eq "#{item_original.id}/#{attachment.id}_#{attachment.filename}"
          end
        end
      end
    end

    context "with zip" do
      it do
        file_model = Gws::Tabular::File[form.current_release]
        expect(file_model.all.count).to eq 1
        item_original = file_model.first

        login_user user1, to: gws_tabular_files_path(site: site, space: space, form: form, view: '-')
        click_on I18n.t("ss.links.download")

        perform_enqueued_jobs do
          within "form#item-form" do
            choose "item[format]", option: "zip"
            choose "item[encoding]", option: encoding

            click_on I18n.t("ss.buttons.download")
          end
        end

        expect(Gws::Job::Log.count).to eq 2
        Gws::Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(SS::Notification.all.count).to eq 1
        notification = SS::Notification.all.first
        expect(notification.group_id).to eq site.id
        expect(notification.member_ids).to eq [ user1.id ]
        expect(notification.user_id).to eq user1.id
        expect(notification.subject).to eq I18n.t("gws/share.mailers.compressed.subject", locale: :ja)
        expect(notification.text).to include("ダウンロードの準備が完了しました。")
        expect(notification.html).to be_blank
        expect(notification.format).to eq "text"
        expect(notification.user_settings).to be_blank
        expect(notification.state).to eq "public"
        expect(notification.send_date).to be_present
        expect(notification.url).to be_blank
        expect(notification.reply_module).to be_blank
        expect(notification.reply_model).to be_blank
        expect(notification.reply_item_id).to be_blank

        match_data = notification.text.match(/^https?:\/\/\w+.+$/mi)
        if match_data
          zip_file_path = match_data.to_s
          zip_file_path = Addressable::URI.parse(zip_file_path).path
          zip_file_path = File.basename(zip_file_path)
        end

        zip_file = SS::DownloadJobFile.find(user1, zip_file_path)
        entries = ::Zip::File.open(zip_file.path)
        entry_names = entries.map { |entry| entry.name }
        expect(entry_names).to have(2).items
        expect(entry_names).to include("files.csv", "#{item_original.id}/#{attachment.id}_#{attachment.filename}")
        entries.get_input_stream("files.csv") do |f|
          tmp_csv_path = tmpfile(extname: ".csv", binary: true) { |tmp| IO.copy_stream(f, tmp) }
          SS::Csv.open(tmp_csv_path) do |csv|
            csv_table = csv.read
            expect(csv_table.length).to eq 1
            csv_table[0].tap do |csv_row|
              expect(csv_row[column1.name]).to eq column1_value1
              expect(csv_row[column2.name]).to eq "#{item_original.id}/#{attachment.id}_#{attachment.filename}"
            end
          end
        end
        entries.get_input_stream("#{item_original.id}/#{attachment.id}_#{attachment.filename}") do |f|
          tmp_attachment_path = tmpfile(binary: true) { |tmp| IO.copy_stream(f, tmp) }
          expect(Fs.compare_file_head(tmp_attachment_path, attachment.path)).to be_truthy
        end
      end
    end
  end
end
