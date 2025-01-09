require 'spec_helper'

describe "opendata_agents_nodes_api", type: :feature, dbscope: :example do
  let!(:node) { create_once :opendata_node_api, name: "opendata_api" }
  let!(:node_dataset) { create_once :opendata_node_dataset }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, filename: "dataset/search" }

  let!(:dataset1) { create(:opendata_dataset, cur_node: node_dataset) }
  let!(:dataset2) { create(:opendata_dataset, cur_node: node_dataset) }
  let!(:dataset3) { create(:opendata_dataset, cur_node: node_dataset) }

  context "package_list" do
    context "no limit and offset" do
      let(:path) { "#{node.full_url}1/package_list" }

      it do
        visit path
        json = JSON.parse(html)
        expect(json["success"]).to be true
        expect(json["result"]).to match_array [dataset1.uuid, dataset2.uuid, dataset3.uuid]
      end
    end

    context "limit given" do
      context "limit 1" do
        let(:path) { "#{node.full_url}1/package_list?limit=1" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array [dataset1.uuid]
        end
      end

      context "limit 0 (no limit)" do
        let(:path) { "#{node.full_url}1/package_list?limit=0" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array [dataset1.uuid, dataset2.uuid, dataset3.uuid]
        end
      end

      context "limit invalid" do
        let(:path) { "#{node.full_url}1/package_list?limit=x" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be false
          expect(json["error"]["limit"]).to eq "Must be a natural number"
        end
      end
    end

    context "offset given" do
      context "offset 1" do
        let(:path) { "#{node.full_url}1/package_list?offset=1" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array [dataset2.uuid, dataset3.uuid]
        end
      end

      context "offset 0" do
        let(:path) { "#{node.full_url}1/package_list?offset=0" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array [dataset1.uuid, dataset2.uuid, dataset3.uuid]
        end
      end

      context "offset invalid" do
        let(:path) { "#{node.full_url}1/package_list?offset=x" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be false
          expect(json["error"]["offset"]).to eq "Must be a natural number"
        end
      end
    end

    context "no limit and offset" do
      context "limit 2 offset 1" do
        let(:path) { "#{node.full_url}1/package_list?limit=2&offset=1" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array [dataset2.uuid, dataset3.uuid]
        end
      end

      context "limit 2 offset 2" do
        let(:path) { "#{node.full_url}1/package_list?limit=2&offset=2" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array [dataset3.uuid]
        end
      end

      context "limit 2 offset 3" do
        let(:path) { "#{node.full_url}1/package_list?limit=2&offset=3" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]).to match_array []
        end
      end

      context "each invalid" do
        let(:path) { "#{node.full_url}1/package_list?limit=-1&offset=-1" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be false
          expect(json["error"]["limit"]).to eq "Must be a natural number"
          expect(json["error"]["offset"]).to eq "Must be a natural number"
        end
      end
    end
  end
end
