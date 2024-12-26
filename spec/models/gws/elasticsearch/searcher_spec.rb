require 'spec_helper'

describe Gws::Elasticsearch::Searcher, type: :model, dbscope: :example, es: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:setting) { Gws::Elasticsearch::Setting::Board.new(cur_site: site, cur_user: user) }
  let(:item) { described_class.new(setting: setting) }
  let(:requests) { [] }

  describe 'searcher' do
    it do
      expect(item.type).to eq [:gws_board_posts]
    end

    context 'when BadRequest' do
      before do
        stub_request(:any, /#{Regexp.escape(site.elasticsearch_hosts.first)}/).to_return do |request|
          if request.uri.path == "/"
            # always respond success for ping request
            {
              status: 200,
              headers: { 'Content-Type' => 'application/json; charset=UTF-8', 'X-elastic-product' => "Elasticsearch" },
              body: File.read("#{Rails.root}/spec/fixtures/gws/elasticsearch/ping.json")
            }
          else
            requests << request.as_json.dup
            if requests.size == 1
              {
                status: 400, #BadRequest
                headers: { 'Content-Type' => 'application/json; charset=UTF-8', 'X-elastic-product' => "Elasticsearch" }
              }
            else
              {
                status: 200,
                headers: { 'Content-Type' => 'application/json; charset=UTF-8', 'X-elastic-product' => "Elasticsearch" }
              }
            end
          end
        end
      end

      it 'changes to simple_query_string' do
        item.keyword = 'String'
        result = item.search

        request = requests.last
        expect(request['body']).to include %({"simple_query_string":{"query":"#{item.keyword}")
      end
    end
  end
end
