require 'spec_helper'

describe "gws_share_files_upload_policy_restricted", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }

  before { login_gws_user }

  before do
    @save_config = SS.config.ss.upload_policy
    SS.config.replace_value_at(:ss, :upload_policy, 'restricted')
  end

  after do
    SS::File.each do |file|
      Fs.rm_rf(file.path) if Fs.exists?(file.path)
      Fs.rm_rf(file.sanitizer_input_path) if Fs.exists?(file.sanitizer_input_path)
    end
    SS.config.replace_value_at(:ss, :upload_policy, @save_config)
  end

  context "basic crud" do
    it do
      visit gws_share_files_path(site)
      click_on folder.name

      #
      # Create
      #
      click_on I18n.t("ss.links.new")
      click_on I18n.t("gws.apis.categories.index")
      wait_for_cbox do
        click_on category.name
      end
      within "form#item-form" do
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t('ss.buttons.upload')
          end
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
      end
      page.accept_alert do
        expect(page).to have_no_css('.file-view')
      end
      expect(Gws::Share::File.all.count).to eq 0
    end
  end
end
