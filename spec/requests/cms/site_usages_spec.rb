require 'spec_helper'

describe "cms_apis_reload_site_usages", type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  before do
    # get and save  auth token
    get sns_auth_token_path(format: :json)
    expect(response.status).to eq 200
    @auth_token = JSON.parse(response.body)["auth_token"]

    # login
    params = {
      'authenticity_token' => @auth_token,
      'item[email]' => user.email,
      'item[password]' => "pass"
    }
    post sns_login_path(format: :json), params: params
    expect(response.status).to eq 204
  end

  it "PUT /.g:site/gws/apis/reload_site_usages.json" do
    put cms_apis_reload_site_usages_path(site: site, format: :json)
    expect(response.status).to eq 200

    json = JSON.parse(response.body)
    expect(json["usage_file_count"]).to be >= 0
    expect(json["usage_db_size"]).to be >= 0
    expect(json["usage_group_count"]).to be >= 0
    expect(json["usage_user_count"]).to be >= 0
    expect(json["usage_calculated_at"].in_time_zone).to be_within(1.minute).of(Time.zone.now)

    site.reload
    expect(site.usage_file_count).to be >= 0
    expect(site.usage_db_size).to be >= 0
    expect(site.usage_group_count).to be >= 0
    expect(site.usage_user_count).to be >= 0
    expect(site.usage_calculated_at.in_time_zone).to be_within(1.minute).of(Time.zone.now)
  end
end
