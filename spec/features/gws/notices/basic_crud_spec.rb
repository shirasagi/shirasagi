require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_notice }
  let(:index_path) { gws_notices_path(site) }
  let(:public_index_path) { gws_public_notices_path(site) }

  context "with auth" do
    before { login_gws_user }

    it_behaves_like 'crud flow'

    it "#public_index" do
      visit public_index_path
      expect(status_code).to eq 200

      click_link item.name
      expect(status_code).to eq 200
    end
  end
end
