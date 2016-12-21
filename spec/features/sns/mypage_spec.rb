require 'spec_helper'

describe "sns_mypage" do
  subject(:index_path) { sns_mypage_path }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  context "with auth" do
    before { login_ss_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end
