require 'spec_helper'

describe 'cms_apis_loop_setting', type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  before do
    # get and save auth token
    get sns_auth_token_path(format: :json)
    expect(response.status).to eq 200
    @auth_token = response.parsed_body['auth_token']

    # login
    params = {
      'authenticity_token' => @auth_token,
      'item[email]' => user.email,
      'item[password]' => 'pass'
    }
    post sns_login_path(format: :json), params: params
    expect(response.status).to eq 204
  end

  def request_path(id)
    cms_apis_loop_setting_path(site: site, id: id, format: :json)
  end

  context 'when loop setting is public' do
    it 'returns 200 and json body' do
      item = create(:cms_loop_setting, site: site, state: 'public', html: "<div>#{unique_id}</div>")

      get request_path(item.id)
      expect(response.status).to eq 200

      json = response.parsed_body
      expect(json['id']).to eq item.id
      expect(json['name']).to eq item.name
      expect(json['html']).to eq item.html.to_s
    end
  end

  context 'when loop setting uses default state' do
    it 'returns 200' do
      item = Cms::LoopSetting.create!(
        cur_site: site,
        name: "loop-setting-#{unique_id}",
        html: "<div>#{unique_id}</div>"
      )
      expect(item.state).to eq 'public'

      get request_path(item.id)
      expect(response.status).to eq 200
    end
  end

  context 'when loop setting state is blank' do
    it 'returns 200 for nil state' do
      item = create(:cms_loop_setting, site: site, state: 'public')
      item.set(state: nil)
      item.reload
      expect(item.state).to be_nil

      get request_path(item.id)
      expect(response.status).to eq 200
    end

    it 'returns 200 for empty string state' do
      item = create(:cms_loop_setting, site: site, state: 'public')
      item.set(state: '')
      item.reload
      expect(item.state).to eq ''

      get request_path(item.id)
      expect(response.status).to eq 200
    end
  end

  context 'when loop setting is closed' do
    it 'returns 403' do
      item = create(:cms_loop_setting, site: site, state: 'closed')

      get request_path(item.id)
      expect(response.status).to eq 403
    end
  end
end
