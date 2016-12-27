require 'spec_helper'

describe "gws_histories", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_histories_path site }
  let(:item) { create :gws_schedule_plan }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      item
      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(item.name)
    end
  end
end
