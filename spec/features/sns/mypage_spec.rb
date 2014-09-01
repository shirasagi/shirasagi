# coding: utf-8
require 'spec_helper'

describe "sns_mypage" do
  before(:all) do
    login_sys_user
  end

  it "#index" do
    visit sns_mypage_path
    expect(status_code).to eq 200
    expect(current_path).not_to eq sns_login_path
  end
end
