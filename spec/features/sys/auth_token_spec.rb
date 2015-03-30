require 'spec_helper'

describe "auth_token", dbscope: :example do
  feature "fetch auth token" do
    scenario "access to html page" do
      visit sys_auth_token_path
      expect(status_code).to eq 200
      expect(current_path).to eq sys_auth_token_path
      expect(response_headers["X-CSRF-Token"]).not_to be_nil
      expect(page).to have_selector("body code#auth_token")
      expect(find("body code#auth_token")).to have_content(response_headers["X-CSRF-Token"])
      # expect(find(:xpath, "//meta[@name='csrf-token']/@content")).to \
      #   have_content(response_headers["X-CSRF-Token"])
    end

    scenario "access to json page" do
      visit "#{sys_auth_token_path}.json"
      expect(status_code).to eq 200
      expect(current_path).to eq "#{sys_auth_token_path}.json"
      expect(response_headers["X-CSRF-Token"]).not_to be_nil
      expect(JSON.parse(body)["auth_token"]).to eq response_headers["X-CSRF-Token"]
    end
  end
end
