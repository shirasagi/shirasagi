require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:folder) { create :gws_notice_folder, cur_site: site, cur_user: user }

  before do
    @save_file_upload_dialog = SS.file_upload_dialog
    SS.file_upload_dialog = :v2
  end

  after do
    SS.file_upload_dialog = @save_file_upload_dialog
  end

  context "when attach file which is ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: SS::UserFile::FILE_MODEL, user: user, basename: "logo-#{unique_id}.png",
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:name) { unique_id }

    it do
      login_user user, to: gws_notice_editables_path(site: site, folder_id: folder, category_id: '-')
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name

        within "#addon-gws-agents-addons-file" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.select_from_list") }
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
        within "#addon-gws-agents-addons-file" do
          expect(page).to have_css('.name', text: file.name)
        end
      end
      # SNS ユーザーファイルを添付した場合、複製が作成されているはず
      expect(SS::File.ne(id: file.id).count).to eq 1
      SS::File.ne(id: file.id).first.tap do |intermediate_file|
        expect(intermediate_file.id).not_to eq file.id
        expect(intermediate_file.name).to eq file.name
        expect(intermediate_file.filename).to eq file.filename
        expect(intermediate_file.content_type).to eq file.content_type
        expect(intermediate_file.size).to eq file.size
        expect(intermediate_file.model).to eq "ss/temp_file"
        expect(intermediate_file.site_id).to be_blank
        expect(intermediate_file.user_id).to eq user.id
        expect(intermediate_file.owner_item_id).to be_blank
        expect(intermediate_file.owner_item_type).to be_blank
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Gws::Notice::Post.first.tap do |after_item|
        expect(after_item.site_id).to eq site.id
        expect(after_item.name).to eq name
        after_item.files.first.tap do |attached_file|
          expect(attached_file.id).not_to eq file.id
          expect(attached_file.name).to eq file.name
          expect(attached_file.filename).to eq file.filename
          expect(attached_file.content_type).to eq file.content_type
          expect(attached_file.size).to eq file.size
          expect(attached_file.site_id).to be_blank
          expect(attached_file.model).to eq "gws/notice/post"
          expect(attached_file.owner_item_id).to eq after_item.id
          expect(attached_file.owner_item_type).to eq after_item.class.name
          expect(attached_file.user_id).to eq user.id
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
