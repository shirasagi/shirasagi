require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before do
    login_gws_user
  end

  context "with standard form" do
    let(:name) { unique_id }
    let(:prefix) { I18n.t("workflow.cloned_name_prefix") }
    let(:name_with_prefix) { "[#{prefix}] #{name}" }

    describe "ss-2579" do
      it do
        visit gws_workflow_files_path(site: site, state: "all")
        click_on I18n.t("ss.links.new")

        within "form#item-form" do
          fill_in "item[name]", with: name
          wait_cbox_open do
            click_on I18n.t("ss.buttons.upload")
          end
        end
        within_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          wait_cbox_close do
            click_on I18n.t("ss.buttons.attach")
          end
        end
        within "form#item-form" do
          expect(page).to have_content("logo.png")
          click_on I18n.t("ss.buttons.save")
        end

        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css(".file-view .name", text: "logo.png")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(Gws::Workflow::File.all.count).to eq 1
        source_file = Gws::Workflow::File.all.first
        expect(source_file.name).to eq name
        expect(source_file.files.count).to eq 1
        source_file_attchment = source_file.files.first
        expect(source_file_attchment.name).to eq "logo.png"
        expect(source_file_attchment.filename).to eq "logo.png"
        expect(source_file_attchment.site_id).to be_blank
        expect(source_file_attchment.model).to eq "gws/workflow/file"
        expect(source_file_attchment.owner_item_id).to eq source_file.id
        expect(source_file_attchment.owner_item_type).to eq source_file.class.name

        visit gws_workflow_files_path(site: site, state: "all")
        click_on name
        click_on I18n.t("ss.links.copy")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end

        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css(".file-view .name", text: "logo.png")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(Gws::Workflow::File.site(site).count).to eq 2
        copy_file = Gws::Workflow::File.all.ne(id: source_file.id).first
        expect(copy_file.name).to eq name_with_prefix
        expect(copy_file.files.count).to eq 1
        copy_file_attchment = copy_file.files.first
        expect(copy_file_attchment.id).not_to eq source_file_attchment.id
        expect(copy_file_attchment.name).to eq source_file_attchment.name
        expect(copy_file_attchment.filename).to eq source_file_attchment.filename
        expect(copy_file_attchment.size).to eq source_file_attchment.size
        expect(copy_file_attchment.site_id).to be_blank
        expect(copy_file_attchment.model).to eq "gws/workflow/file"
        expect(copy_file_attchment.owner_item_id).to eq copy_file.id
        expect(copy_file_attchment.owner_item_type).to eq copy_file.class.name
      end
    end

    describe "with text that contains file's url" do
      shared_examples "file url replacement flow" do
        it do
          visit gws_workflow_files_path(site: site, state: "all")
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            fill_in "item[name]", with: name
            wait_cbox_open do
              click_on I18n.t("ss.buttons.upload")
            end
          end
          within_cbox do
            attach_file "item[in_files][]", file_path
            wait_cbox_close do
              click_on I18n.t("ss.buttons.attach")
            end
          end
          within "form#item-form" do
            expect(page).to have_content(::File.basename(file_path))
            expect(SS::TempFile.count).to eq 1
            fill_in "item[text]", with: test_url
            click_on I18n.t("ss.buttons.save")
          end

          wait_for_notice I18n.t('ss.notice.saved')
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(Gws::Workflow::File.site(site).count).to eq 1

          visit gws_workflow_files_path(site: site, state: "all")
          click_on name
          click_on I18n.t("ss.links.copy")
          within "form#item-form" do
            click_on I18n.t("ss.buttons.save")
          end

          wait_for_notice I18n.t('ss.notice.saved')
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(Gws::Workflow::File.site(site).count).to eq 2
          expect(Gws::Workflow::File.site(site).where(name: name_with_prefix)).to be_present
          Gws::Workflow::File.site(site).where(name: name_with_prefix).first.tap do |item|
            expect(item.text).to eq expected_url
          end
        end
      end

      context "when image is given" do
        let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
        let(:test_url) { SS::TempFile.first.url }
        let(:expected_url) do
          item = Gws::Workflow::File.site(site).where(name: name_with_prefix).first
          item.files.first.url
        end

        it_behaves_like "file url replacement flow"
      end

      context "when image's thumbnail is given" do
        let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
        let(:test_url) { SS::TempFile.first.thumb.url }
        let(:expected_url) do
          item = Gws::Workflow::File.site(site).where(name: name_with_prefix).first
          item.files.first.thumb.url
        end

        it_behaves_like "file url replacement flow"
      end

      context "when pdf is given" do
        let(:file_path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }
        let(:test_url) { SS::TempFile.first.url }
        let(:expected_url) do
          item = Gws::Workflow::File.site(site).where(name: name_with_prefix).first
          item.files.first.url
        end

        it_behaves_like "file url replacement flow"
      end
    end
  end
end
