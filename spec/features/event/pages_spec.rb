# coding: utf-8
require 'spec_helper'

describe "event_pages" do
  subject(:site) { cms_site }
  subject(:node) { create_once :event_node_page, name: "event" }
  subject(:item) { Event::Page.last }
  subject(:index_path) { event_pages_path site.host, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end
