require 'spec_helper'

describe "gws_schedule_custom_group_plans", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:path) { gws_schedule_custom_group_plans_path site, custom_group }
  let(:item) { create :gws_schedule_plan }
  let(:custom_group) { create :gws_custom_group }

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
      custom_group
      visit path
      expect(status_code).to eq 200
      expect(page).to have_content(custom_group.name)
    end
  end
end
