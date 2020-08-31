require 'spec_helper'

describe "cms_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:file) { tmp_ss_file(user: user, contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf") }
  let(:html) do
    "<p><a class=\"icon-pdf\" href=\"#{file.url}\">#{file.humanized_name}</a></p>"
  end
  let!(:item) { create(:cms_notice, site: site, cur_user: user, html: html, file_ids: [ file.id ]) }

  context "when <a> within ckeditor's iframe is clicked" do
    before { login_cms_user }

    it do
      visit cms_public_notice_path(site: site, id: item)

      new_window = nil
      within_frame find("iframe.cke_wysiwyg_frame") do
        new_window = window_opened_by { click_on file.humanized_name }
      end

      # new window (tab) is opened and pdf is show
      expect(new_window).to be_present
      within_window new_window do
        expect(page).to have_css("embed[type='application/pdf']")
      end
    end
  end
end
