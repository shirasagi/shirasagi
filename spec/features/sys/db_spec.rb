# coding: utf-8
require 'spec_helper'

describe "sys_db" do
  before { login_sys_user }

  it "#index" do
    visit sys_db_colls_path
    expect(status_code).to eq 200
    expect(current_path).not_to eq sns_login_path
  end
end
