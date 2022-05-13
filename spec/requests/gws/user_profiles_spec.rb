require 'spec_helper'

describe "gws_user_profiles", type: :request, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }
  let(:presence) do
    item = Gws::UserPresence.new(cur_user: user, cur_site: site)
    item.presence_state = 'available'
    item.presence_plan = unique_id
    item.presence_memo = unique_id
    item.save ? item : nil
  end

  before do
    # get and save  auth token
    get sns_auth_token_path(format: :json)
    @auth_token = JSON.parse(response.body)["auth_token"]

    # login
    params = {
      'authenticity_token' => @auth_token,
      'item[email]' => user.email,
      'item[password]' => "pass"
    }
    post sns_login_path(format: :json), params: params
  end

  it "GET /.g:site/gws/user_profile.json" do
    expect(presence.present?).to be_truthy

    get gws_user_profile_path(site: site, format: :json)
    expect(response.status).to eq 200

    json = JSON.parse(response.body)
    expect(json['user']['_id']).to eq user.id
    expect(json['user']['presence_state']).to eq 'available'
    expect(json['user']['presence_state_label']).to eq states['available'] # 在席
    expect(json['user']['presence_state_style']).to eq 'active'
    expect(json['user']['presence_plan'].present?).to be_truthy
    expect(json['user']['presence_memo'].present?).to be_truthy
    expect(json['group']['_id'].present?).to be_truthy
    expect(json['imap_setting']['address'].present?).to be_truthy
  end
end
