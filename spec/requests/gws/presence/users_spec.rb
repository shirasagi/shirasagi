require 'spec_helper'

describe 'gws_presence_users', type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:custom_group) { create :gws_custom_group, member_ids: [user.id] }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:users_path) { gws_presence_apis_users_path(site: site.id, format: :json) }
  let(:group_users_path) do
    gws_presence_apis_group_users_path(site: site.id, group: gws_user.gws_default_group.id, format: :json)
  end
  let(:custom_group_users_path) do
    gws_presence_apis_custom_group_users_path(site: site.id, group: custom_group.id, format: :json)
  end
  let(:update_path) { gws_presence_apis_user_path(site: site.id, id: gws_user.id, format: :json) }
  let(:states_path) { states_gws_presence_apis_users_path(site: site.id, format: :json) }
  let(:presence_states) { Gws::UserPresence.new.state_options.map(&:reverse).to_h }
  let(:presence_styles) { Gws::UserPresence.new.state_styles }

  shared_examples "what gws presence is" do
    it "GET /.g:site/presence/users.json" do
      get users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][1]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
    end

    it "GET /.g:site/presence/g-:group/users.json" do
      get group_users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][1]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
    end

    it "GET /.g:site/presence/c-:group/users.json" do
      get custom_group_users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][0]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
    end

    it "PUT /.g:site/presence/users.json" do
      params = {
        presence_state: "available",
        presence_memo: "modified-memo",
        presence_plan: "modified-plan"
      }
      put update_path, params: params, headers: @headers
      expect(response.status).to eq 200
      gws_admin = JSON.parse(response.body)
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
      expect(gws_admin["presence_state"]).to eq "available"
      expect(gws_admin["presence_state_label"]).to eq presence_states["available"]
      expect(gws_admin["presence_state_style"]).to eq presence_styles["available"]
      expect(gws_admin["presence_memo"]).to eq "modified-memo"
      expect(gws_admin["presence_plan"]).to eq "modified-plan"
      expect(gws_admin["editable"]).to eq true

      get group_users_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      gws_admin = json["items"][1]
      expect(gws_admin["id"]).to eq gws_user.id
      expect(gws_admin["name"]).to eq gws_user.name
      expect(gws_admin["presence_state"]).to eq "available"
      expect(gws_admin["presence_state_label"]).to eq presence_states["available"]
      expect(gws_admin["presence_state_style"]).to eq presence_styles["available"]
      expect(gws_admin["presence_memo"]).to eq "modified-memo"
      expect(gws_admin["presence_plan"]).to eq "modified-plan"
      expect(gws_admin["editable"]).to eq true
    end

    it "GET /.g:site/presence/users/states.json" do
      get states_path, headers: @headers
      expect(response.status).to eq 200

      json = JSON.parse(response.body)
      available = json["items"][0]
      expect(available["name"]).to eq "available"
      expect(available["label"]).to eq presence_states["available"]
      expect(available["style"]).to eq presence_styles["available"]
      expect(available["order"]).to eq 0
    end
  end

  context "login with gws-admin" do
    before do
      # get and save  auth token
      get auth_token_path
      auth_token = JSON.parse(response.body)["auth_token"]
      @headers = nil

      # login
      params = {
        'authenticity_token' => auth_token,
        'item[email]' => gws_user.email,
        'item[password]' => "pass"
      }
      post sns_login_path(format: :json), params: params
    end

    include_context "what gws presence is"
  end

  context "token auth with gws-admin" do
    before do
      token = SS::OAuth2::Token.create_token!(gws_user, Gws::Role.permission_names)
      @headers = {
        "Authorization" => "Bearer #{token.token}"
      }
    end

    include_context "what gws presence is"
  end
end
