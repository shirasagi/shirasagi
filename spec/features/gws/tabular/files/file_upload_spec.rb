require 'spec_helper'

describe Gws::Tabular::FilesController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1, workflow_state: 'disabled'
  end
  let(:allowed_extensions) { nil }
  let!(:image_column) do
    create(
      :gws_tabular_column_file_upload_field, cur_site: site, cur_form: form, order: 10,
      allowed_extensions: allowed_extensions)
  end

  before do
    Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: admin).perform_now(form.id.to_s)

    expect(Gws::Job::Log.count).to eq 1
    Gws::Job::Log.all.each do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end
  end

  context "with gws/tabular/file_upload_fields" do
    let(:image_attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:image_attachment) do
      tmp_ss_file(user: admin, contents: image_attachment_path, basename: "logo-#{unique_id}.png")
    end
    let(:pdf_attachment_path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }
    let!(:pdf_attachment) do
      tmp_ss_file(user: admin, contents: pdf_attachment_path, basename: "ss-#{unique_id}.pdf")
    end

    before do
      login_user admin
    end

    context "all types are allowed (no restrictions)" do
      context "when uploaded image is selected" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            # V2形式のファイルアップロードダイアログのみ対応
            attach_to_ss_file_field_v2 "item[col_#{image_column.id}_id]", image_attachment
            expect(page).to have_css("[data-column-id='#{image_column.id}']", text: image_attachment.humanized_name)
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          item_model = Gws::Tabular::File[form.current_release]
          expect(item_model.all.count).to eq 1

          item = item_model.first
          item.read_tabular_value(image_column).tap do |item_image_value|
            expect(item_image_value).to be_present
            expect(item_image_value.id).to eq image_attachment.id
          end
          SS::File.find(image_attachment.id).tap do |afeter_attached|
            expect(afeter_attached.owner_item_id).to eq item.id
            expect(afeter_attached.owner_item_type).to eq item.class.name
          end
        end
      end

      context "when uploaded pdf is selected" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            # V2形式のファイルアップロードダイアログのみ対応
            attach_to_ss_file_field_v2 "item[col_#{image_column.id}_id]", pdf_attachment
            expect(page).to have_css("[data-column-id='#{image_column.id}']", text: pdf_attachment.humanized_name)
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          item_model = Gws::Tabular::File[form.current_release]
          expect(item_model.all.count).to eq 1

          item = item_model.first
          item.read_tabular_value(image_column).tap do |item_image_value|
            expect(item_image_value).to be_present
            expect(item_image_value.id).to eq pdf_attachment.id
          end
          SS::File.find(pdf_attachment.id).tap do |afeter_attached|
            expect(afeter_attached.owner_item_id).to eq item.id
            expect(afeter_attached.owner_item_type).to eq item.class.name
          end
        end
      end

      context "when new image is uploaded" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            # V2形式のファイルアップロードダイアログのみ対応
            upload_to_ss_file_field_v2 "item[col_#{image_column.id}_id]", image_attachment_path
            basename = ::File.basename(image_attachment_path, ".*")
            expect(page).to have_css("[data-column-id='#{image_column.id}']", text: basename)
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          item_model = Gws::Tabular::File[form.current_release]
          expect(item_model.all.count).to eq 1

          item = item_model.first
          item.read_tabular_value(image_column).tap do |item_image_value|
            expect(item_image_value).to be_present
            expect(item_image_value.filename).to eq ::File.basename(image_attachment_path)
          end
        end
      end

      context "when new pdf is uploaded" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            # V2形式のファイルアップロードダイアログのみ対応
            upload_to_ss_file_field_v2 "item[col_#{image_column.id}_id]", pdf_attachment_path
            basename = ::File.basename(pdf_attachment_path, ".*")
            expect(page).to have_css("[data-column-id='#{image_column.id}']", text: basename)
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          item_model = Gws::Tabular::File[form.current_release]
          expect(item_model.all.count).to eq 1

          item = item_model.first
          item.read_tabular_value(image_column).tap do |item_image_value|
            expect(item_image_value).to be_present
            expect(item_image_value.filename).to eq ::File.basename(pdf_attachment_path)
          end
        end
      end
    end

    context "only .png is allowed" do
      let(:allowed_extensions) { %w(.png) }

      context "when uploaded image is selected" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            # V2形式のファイルアップロードダイアログのみ対応
            attach_to_ss_file_field_v2 "item[col_#{image_column.id}_id]", image_attachment
            expect(page).to have_css("[data-column-id='#{image_column.id}']", text: image_attachment.humanized_name)
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          item_model = Gws::Tabular::File[form.current_release]
          expect(item_model.all.count).to eq 1

          item = item_model.first
          item.read_tabular_value(image_column).tap do |item_image_value|
            expect(item_image_value).to be_present
            expect(item_image_value.id).to eq image_attachment.id
          end
          SS::File.find(image_attachment.id).tap do |afeter_attached|
            expect(afeter_attached.owner_item_id).to eq item.id
            expect(afeter_attached.owner_item_type).to eq item.class.name
          end
        end
      end

      context "when uploaded pdf is selected" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
          end
          wait_for_event_fired "turbo:frame-load" do
            within_dialog do
              within ".cms-tabs" do
                click_on I18n.t("ss.buttons.select_from_list")
              end
            end
          end
          within_dialog do
            # PDF は表示されていない。PNG のみが表示されているはず。
            expect(page).to have_css(".file-view[data-id='#{image_attachment.id}']")
            expect(page).to have_no_css(".file-view[data-id='#{pdf_attachment.id}']")
          end
        end
      end

      context "when new image is uploaded" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            # V2形式のファイルアップロードダイアログのみ対応
            upload_to_ss_file_field_v2 "item[col_#{image_column.id}_id]", image_attachment_path

            basename = ::File.basename(image_attachment_path, ".*")
            expect(page).to have_css("[data-column-id='#{image_column.id}']", text: basename)
            click_on I18n.t("ss.buttons.save")
          end
          wait_for_notice I18n.t("ss.notice.saved")

          item_model = Gws::Tabular::File[form.current_release]
          expect(item_model.all.count).to eq 1

          item = item_model.first
          item.read_tabular_value(image_column).tap do |item_image_value|
            expect(item_image_value).to be_present
            expect(item_image_value.filename).to eq ::File.basename(image_attachment_path)
          end
        end
      end

      context "when new pdf is uploaded" do
        it do
          visit gws_tabular_files_path(site: site, space: space, form: form, view: '-')
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
          end
          within_dialog do
            wait_event_to_fire "ss:tempFile:addedWaitingList" do
              attach_file "in_files", pdf_attachment_path
            end
          end
          within_dialog do
            within "form" do
              within first(".index tbody tr") do
                list = allowed_extensions.join(" / ")
                message = I18n.t("errors.messages.unable_to_accept_file", allowed_format_list: list)
                message = I18n.t("errors.format", attribute: SS::File.t(:in_files), message: message)
                expect(page).to have_css(".errors", text: message)
              end
            end
          end
        end
      end
    end
  end
end
