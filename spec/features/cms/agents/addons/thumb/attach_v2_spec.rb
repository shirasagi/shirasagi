require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let!(:site){ cms_site }
  let!(:user){ cms_user }
  let!(:node) { create :article_node_page, cur_site: site }
  let(:filename) { "#{unique_id}.png" }
  let!(:item) { create :article_page, cur_user: user, cur_site: site, cur_node: node, state: "closed" }

  before do
    @save_file_upload_dialog = SS.file_upload_dialog
    SS.file_upload_dialog = :v2
  end

  after do
    SS.file_upload_dialog = @save_file_upload_dialog
  end

  shared_examples "attach and save" do
    it do
      login_user user, to: edit_article_page_path(site: site, cid: node, id: item)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within "form#item-form" do
        within "#addon-cms-agents-addons-thumb" do
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
      el = page.find(:checkbox, file_type)
      unless el["checked"]
        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within "form.search" do
              check file_type
            end
          end
        end
      end
      within_dialog do
        expect(page).to have_css('.file-view', text: file.name)
        wait_for_cbox_closed { click_on file.name }
      end
      within "form#item-form" do
        within "#addon-cms-agents-addons-thumb" do
          expect(page).to have_css('.ss-file-field-v2 .humanized-name', text: file.humanized_name)
        end
      end
      # サムネイルの場合、CMS 共有ファイルや SNS ユーザーファイルを添付しても（この時点では）複製は作成されない
      expect(SS::File.ne(id: file.id).count).to eq 0
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      if SS::File::COPY_REQUIRED_MODELS.include?(file.model)
        SS::File.find(file.id).tap do |after_file|
          expect(after_file.model).to eq file.model
          expect(after_file.owner_item_id).to be_blank
          expect(after_file.owner_item_type).to be_blank
        end

        item.class.find(item.id).tap do |after_item|
          expect(after_item.thumb_id).to be_present
          expect(after_item.thumb_id).not_to eq file.id
        end
      else
        SS::File.find(file.id).tap do |after_file|
          expect(after_file.model).not_to eq file.model
          expect(after_file.owner_item_id).to eq item.id
          expect(after_file.owner_item_type).to eq item.class.name
        end

        item.class.find(item.id).tap do |after_item|
          expect(after_item.thumb_id).to be_present
          expect(after_item.thumb_id).to eq file.id
        end
      end
    end
  end

  context "with cms/temp_file(ss/temp_file)" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: user, site: site, node: node, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("mongoid.models.ss/temp_file") }

    it_behaves_like "attach and save"
  end

  context "with ss/user_file" do
    let!(:file) do
      tmp_ss_file(
        SS::UserFile, model: SS::UserFile::FILE_MODEL, user: user, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("mongoid.models.ss/user_file") }

    it_behaves_like "attach and save"
  end

  context "with cms/file" do
    let!(:file) do
      tmp_ss_file(
        Cms::File, model: Cms::File::FILE_MODEL, user: user, site: site, basename: filename,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:file_type) { I18n.t("mongoid.models.cms/file") }

    it_behaves_like "attach and save"
  end
end
