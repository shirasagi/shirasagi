require 'spec_helper'

describe "auth_token", dbscope: :example do
  feature "fetch auth token" do
    scenario "access to html page" do
      visit sns_auth_token_path
      expect(status_code).to eq 200
      expect(current_path).to eq sns_auth_token_path
      expect(response_headers["X-CSRF-Token"]).not_to be_nil
      expect(response_headers["Content-Type"]).to eq "text/plain"
      expect(page.html).to eq response_headers["X-CSRF-Token"]
    end

    scenario "access to json page" do
      visit "#{sns_auth_token_path}.json"
      expect(status_code).to eq 200
      expect(current_path).to eq "#{sns_auth_token_path}.json"
      expect(response_headers["X-CSRF-Token"]).not_to be_nil
      expect(JSON.parse(body)["auth_token"]).to eq response_headers["X-CSRF-Token"]
    end
  end
end
