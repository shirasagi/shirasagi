require 'spec_helper'

describe "uploader_files", type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :uploader_node_file, cur_site: site }

  before { login_cms_user }

  context "when a user uploads a scss file" do
    context "with valid scss" do
      it do
        visit uploader_files_path(site: site, cid: node)
        click_on I18n.t("ss.links.upload")

        within "form" do
          attach_file "item[files][]", "#{Rails.root}/spec/fixtures/uploader/style.scss"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(page).to have_css("a.file", text: "style.scss")
        expect(page).to have_css("a.file", text: "style.css")

        expect(File.size("#{node.path}/style.scss")).to be > 0
        expect(File.size("#{node.path}/style.css")).to be > 0
      end
    end

    context "with invalid scss" do
      it do
        visit uploader_files_path(site: site, cid: node)
        click_on I18n.t("ss.links.upload")

        within "form" do
          attach_file "item[files][]", "#{Rails.root}/spec/fixtures/uploader/invalid.scss"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_error "Undefined variable."

        expect(File.size("#{node.path}/invalid.scss")).to be > 0
        expect(File.exist?("#{node.path}/invalid.css")).to be_falsey
      end
    end
  end

  context "when a user edits a scss file" do
    let(:fullpath) { "#{Rails.root}/spec/fixtures/uploader/style.scss" }
    let(:basename) { File.basename(fullpath) }

    before do
      ::FileUtils.mkdir_p node.path
      ::FileUtils.cp fullpath, node.path
    end

    context "with valid scss" do
      it do
        visit uploader_files_path(site: site, cid: node)
        click_on basename
        click_on I18n.t("ss.links.edit")

        within "form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(File.size("#{node.path}/style.scss")).to be > 0
        expect(File.size("#{node.path}/style.css")).to be > 0
      end
    end

    context "with invalid scss" do
      let(:fullpath) { "#{Rails.root}/spec/fixtures/uploader/invalid.scss" }
      let(:basename) { File.basename(fullpath) }

      before do
        ::FileUtils.mkdir_p node.path
        ::FileUtils.cp fullpath, node.path
      end

      it do
        visit uploader_files_path(site: site, cid: node)
        click_on basename
        click_on I18n.t("ss.links.edit")

        within "form" do
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_error "Undefined variable."

        expect(File.size("#{node.path}/invalid.scss")).to be > 0
        expect(File.exist?("#{node.path}/invalid.css")).to be_falsey
      end
    end
  end
end
