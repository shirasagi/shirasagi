require 'spec_helper'

describe "gws_report_files", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:column9) { create(:gws_column_file_upload, cur_site: site, form: form, order: 90, required: "optional") }

  before do
    @save_file_upload_dialog = SS.file_upload_dialog
    SS.file_upload_dialog = :v2
  end

  after do
    SS.file_upload_dialog = @save_file_upload_dialog
  end

  context "when upload file which is ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: SS::UserFile::FILE_MODEL, user: user, basename: "logo-#{unique_id}.png",
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:name) { unique_id }

    it do
      login_user user, to: gws_report_files_main_path(site: site)
      within "#menu" do
        wait_for_event_fired("ss:dropdownOpened") { click_on I18n.t("ss.links.new") }
        within ".gws-dropdown-menu" do
          click_on form.name
        end
      end

      within "form#item-form" do
        fill_in "item[name]", with: name

        within "#custom_#{column9.id}_0" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
        end
      end
      wait_for_event_fired "turbo:frame-load" do
        within_dialog do
          within ".cms-tabs" do
            click_on I18n.t("ss.buttons.select_from_list")
          end
        end
      end
      within_dialog do
        wait_for_event_fired "turbo:frame-load" do
          within "form.search" do
            # check I18n.t("sns.user_file")
            first("[name='s[types][]'][value='user_file']").click
          end
        end
      end
      within_dialog do
        expect(page).to have_css('.file-view', text: file.name)
        wait_for_cbox_closed { click_on file.name }
      end
      within "form#item-form" do
        within "#custom_#{column9.id}_0" do
          expect(page).to have_css('.humanized-name', text: file.humanized_name)
        end
      end
      # SNS ユーザーファイルを添付しても（この時点では）複製は作成されない
      expect(SS::File.ne(id: file.id).count).to eq 0
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::Report::File.first.tap do |after_item|
        expect(after_item.site_id).to eq site.id
        expect(after_item.name).to eq name
        after_item.column_values.where(column_id: column9.id).first.tap do |cv|
          expect(cv.files.count).to eq 1
          cv.files.first.tap do |cv_file|
            expect(cv_file.id).not_to eq file.id
            expect(cv_file.name).to eq file.name
            expect(cv_file.filename).to eq file.filename
            expect(cv_file.content_type).to eq file.content_type
            expect(cv_file.size).to eq file.size
            expect(cv_file.site_id).to be_blank
            expect(cv_file.model).to eq "Gws::Report::File"
            expect(cv_file.owner_item_id).to eq after_item.id
            expect(cv_file.owner_item_type).to eq after_item.class.name
            expect(cv_file.user_id).to eq user.id
          end
        end
      end

      SS::File.find(file.id).tap do |after_file|
        expect(after_file.model).to eq file.model
        expect(after_file.owner_item_id).to be_blank
        expect(after_file.owner_item_type).to be_blank
      end
    end
  end
end
