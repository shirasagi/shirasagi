require 'spec_helper'

describe "mobile", type: :feature do
  let!(:user) { cms_user }
  let!(:site) { create(:cms_site_unique, mobile_state: "enabled", mobile_location: "/#{unique_id}") }
  let!(:sub_site) { create(:cms_site_subdir, parent_id: site.id, mobile_state: "disabled") }
  let(:file_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
  let(:file) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "keyvisual.jpg") }
  let!(:sub_site_index) do
    html = <<~HTML
      <img src="#{file.full_url}">
      <p>#{ss_japanese_text}</p>
    HTML
    create(:cms_page, cur_user: user, cur_site: sub_site, filename: "index.html", html: html)
  end

  context "sub site which has mobile disabled" do
    it do
      visit site.mobile_full_url + sub_site.subdir + "/" + sub_site_index.filename
      expect(status_code).to eq 200
    end
  end
end
