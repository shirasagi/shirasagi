require 'spec_helper'

describe 'gws_memo_apis_folders', type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_memo_folder }

  context "with auth" do
    before { login_gws_user }

    it "manageable.html" do
      visit gws_memo_apis_folders_path(site: site, mode: 'manageable', single: true)
      expect(page).to have_content(item.name)
    end

    it "all.json" do
      visit gws_memo_apis_folders_path(site: site, mode: 'all', single: true, format: 'json')
      expect(page).to have_content(item.name)
    end

    it "invalid params[:mode]" do
      visit gws_memo_apis_folders_path(site: site, mode: 'manageable/all', single: true)
      expect(page).to have_no_content(item.name)
    end
  end
end
