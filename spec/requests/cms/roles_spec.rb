require 'spec_helper'

describe Cms::RoleEditsController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:admin) { cms_user }
  let!(:role) { admin.cms_roles.site(site).first }

  context "privilege-escalation-vulnerability" do
    let!(:user) { create :cms_test_user, group_ids: [ group.id ] }

    before do
      # get and save  auth token
      get sns_auth_token_path(format: :json)
      expect(response.status).to eq 200
      @auth_token = response.parsed_body["auth_token"]

      # login
      params = {
        'authenticity_token' => @auth_token,
        'item[email]' => user.email,
        'item[password]' => ss_pass
      }
      post sns_login_path(format: :json), params: params
      expect(response.status).to eq 204
    end

    it do
      params = {
        'authenticity_token' => @auth_token,
        "item[cms_role_ids][]" => role.id
      }
      put cms_group_role_path(site: site, group_id: group, format: :json), params: params
      expect(response.status).to eq 403
      expect(response.parsed_body).to be_a(Hash)

      Cms::User.find(user.id).tap do |user_after_edit|
        expect(user_after_edit.cms_role_ids).to be_blank
      end
    end
  end
end
