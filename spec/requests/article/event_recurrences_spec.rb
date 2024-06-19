require 'spec_helper'

describe "Article::PagesController", type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:article_node_page) }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let!(:page) { create(:article_page, cur_node: node) }
  let!(:edit_exclude_dates_path) { event_apis_edit_exclude_dates_path(site.id) }
  let!(:admin_user) { cms_user }
  
  context "admin user" do 
    before do
      # get and save  auth token
      get auth_token_path
      @auth_token = JSON.parse(response.body)["auth_token"]

      # login
      params = {
        'authenticity_token' => @auth_token,
        'item[email]' => admin_user.email,
        'item[password]' => admin_user.in_password
      }
      post sns_login_path(format: :json), params: params
    end
    describe "check html" do
      let(:event_name) { "event_name-#{unique_id}" }
      let(:start_on1) { Date.parse("2023/02/06") }
      let(:until_on1) { (start_on1 + 2.days).to_date }
      let(:event_deadline) { "" }
      let(:event_recurrence) do
        { kind: "date", start_at: start_on1, frequency: "daily", until_on: until_on1}
      end

      it " will check if the html have the specification block." do
        page.update(event_name: event_name, event_deadline: event_deadline, event_recurrences: [event_recurrence])
        params = {
          authenticity_token: @auth_token,
          index: 1,
          item:{
            event_recurrences: [
              {
                in_update_from_view: ""
              },
              {
                in_update_from_view: "1",
                in_all_day: "",
                in_exclude_dates: "",
                in_start_on: start_on1,
                in_until_on: until_on1,
                in_start_time: start_on1,
                in_by_days: [""]
              }
            ]
          }
        }
        post edit_exclude_dates_path, params: params
        expect(response).to have_http_status(:success)
        expect(response.body.to_s).to include("information__usage")
      end
    end
  end
end