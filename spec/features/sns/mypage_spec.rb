require 'spec_helper'

describe "sns_mypage" do
  before(:all) { login_sys_user }
  subject(:url) { sns_mypage_path }

  it "#index" do
    visit url
    expect(status_code).to eq 200
    expect(current_path).to eq url
  end
end
