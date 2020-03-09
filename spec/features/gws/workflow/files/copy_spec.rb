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
          click_on I18n.t("ss.buttons.upload")
        end
        wait_for_cbox do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
          click_on I18n.t("ss.buttons.attach")
        end
        within "form#item-form" do
          expect(page).to have_content("logo.png")
          click_on I18n.t("ss.buttons.save")
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_css(".file-view .name", text: "logo.png")

        visit gws_workflow_files_path(site: site, state: "all")
        click_on name
        click_on I18n.t("ss.links.copy")
        within "form" do
          click_on I18n.t("ss.buttons.save")
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_css(".file-view .name", text: "logo.png")

        expect(Gws::Workflow::File.site(site).count).to eq 2
        expect(Gws::Workflow::File.site(site).where(name: name_with_prefix)).to be_present
      end
    end

    describe "with text that contains file's url" do
      shared_examples "file url replacement flow" do
        it do
          visit gws_workflow_files_path(site: site, state: "all")
          click_on I18n.t("ss.links.new")

          within "form#item-form" do
            fill_in "item[name]", with: name
            click_on I18n.t("ss.buttons.upload")
          end
          wait_for_cbox do
            attach_file "item[in_files][]", file_path
            click_on I18n.t("ss.buttons.attach")
          end
          within "form#item-form" do
            expect(page).to have_content(::File.basename(file_path))
            expect(SS::TempFile.count).to eq 1
            fill_in "item[text]", with: test_url
            click_on I18n.t("ss.buttons.save")
          end

          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          expect(Gws::Workflow::File.site(site).count).to eq 1

          visit gws_workflow_files_path(site: site, state: "all")
          click_on name
          click_on I18n.t("ss.links.copy")
          within "form" do
            click_on I18n.t("ss.buttons.save")
          end

          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
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
