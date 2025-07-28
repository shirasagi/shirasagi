require 'spec_helper'

describe "cms_apis_node_temp_files", type: :feature, dbscope: :example do
  let(:multibyte_filename_state) { 'disabled' }
  let(:site) { cms_site.set(multibyte_filename_state: multibyte_filename_state) }
  let(:item) do
    tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
  end
  let(:node) { create :cms_node }
  let(:index_path) { cms_apis_node_temp_files_path site.id, node.id }
  let(:new_path) { new_cms_apis_node_temp_file_path site.id, node.id }
  let(:show_path) { cms_apis_node_temp_file_path site.id, node.id, item }
  let(:edit_path) { edit_cms_apis_node_temp_file_path site.id, node.id, item }
  let(:delete_path) { delete_cms_apis_node_temp_file_path site.id, node.id, item }
  let(:select_path) { select_cms_apis_node_temp_file_path site.id, node.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      path = "#{Rails.root}/spec/fixtures/ss/logo.png"
      basename = File.basename(path)

      visit new_path
      within "#ajax-form" do
        attach_file "item[in_files][]", path
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
      expect(page).to have_no_css('#errorExplanation')

      expect(Cms::TempFile.all.count).to eq 1
      Cms::TempFile.all.first.tap do |file|
        expect(file.site_id).to eq site.id
        expect(file.user_id).to eq cms_user.id
        expect(file.node_id).to eq node.id
        expect(file.name).to eq basename
        expect(file.filename).to eq basename
        expect(file.content_type).to eq "image/png"
        expect(file.size).to eq File.size(path)
      end
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#select" do
      visit select_path
      expect(status_code).to eq 200
    end

    it "#edit" do
      visit edit_path
      within "#ajax-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
      expect(page).to have_no_css('#errorExplanation')
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end
  end

  context "when filename is use multibyte character" do
    before { login_cms_user }

    context "when multibyte_filename_state is disabled" do
      it "#new" do
        visit new_path
        within "#ajax-form" do
          attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/ロゴ.png"
          click_button I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#errorExplanation')
      end
    end

    context "when multibyte_filename_state is enabled" do
      let(:multibyte_filename_state) { [ nil, 'enabled' ].sample }

      it "#new" do
        path = "#{Rails.root}/spec/fixtures/ss/ロゴ.png"

        visit new_path
        within "#ajax-form" do
          attach_file "item[in_files][]", path
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).to have_no_css("form#item-form")
        expect(page).to have_no_css('#errorExplanation')

        expect(Cms::TempFile.all.count).to eq 1
        Cms::TempFile.all.first.tap do |file|
          expect(file.site_id).to eq site.id
          expect(file.user_id).to eq cms_user.id
          expect(file.node_id).to eq node.id
          # name はマルチバイト文字OK、filenameはNG
          expect(file.name).to eq File.basename(path)
          expect(file.filename).to eq "__.png"
          expect(file.content_type).to eq "image/png"
          expect(file.size).to eq File.size(path)
        end
      end
    end
  end
end
