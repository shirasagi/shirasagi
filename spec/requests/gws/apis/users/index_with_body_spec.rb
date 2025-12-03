require 'spec_helper'

# 動機・目的: HTTP GET で大量のパラメータを渡したい
#
# 単に Query Parameter にパラメータを指定すると 414 URI Too Long エラーが発生する可能性が高まる。
# このエラーを回避するために Request Body に JSON か form-data 形式でパラメータを渡すことが真っ先に思い浮かぶが、
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Methods/GET には、以下のような記述がある
#
# > Requests using GET should only be used to request data and shouldn't contain a body.
# >
# > Note:
# > The semantics of sending a message body in GET requests are undefined.
# > Some servers may reject the request with a 4XX client error response.
#
# HTTP の仕様では禁止されていないが、動作は未定義。
#
# そこで次のようにする。
#
# 1. 大量パラメータを渡したい。Query Parameter は利用できないので Request Body にパラメータを設定する。
# 2. HTTP Method として GET は利用できないので POST を利用する。
# 3. パラメータに Rails の拡張 _method: "GET" をセットすることで routes.rb には GET で定義されているアクションを呼び出す。
describe 'GET gws/apis/users#index', type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  it do
    get sns_auth_token_path(format: :json)
    auth_token = response.parsed_body["auth_token"]

    login_params = {
      'authenticity_token' => auth_token,
      'item[email]' => user.email,
      'item[password]' => "pass"
    }
    post sns_login_path(format: :json), params: login_params

    users_params = {
      '_method' => 'GET',
      'selected[]' => [ user.id ]
    }
    post gws_apis_users_path(site: site, format: :html), params: users_params

    fragment = response.parsed_body
    fragment.css(".list-item[data-id='#{user.id}']").tap do |list_items|
      expect(list_items).to have(1).items
      list_item = list_items[0]
      check_box = list_item.css('[type="checkbox"]').first
      expect(check_box["disabled"]).to be_truthy
    end
  end
end
