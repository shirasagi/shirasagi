require 'spec_helper'

describe "gws_histories", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_histories_path site }
  let(:item) { create :gws_schedule_plan }

  it "without login" do
    visit path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit path
    expect(status_code).to eq 403
  end

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
