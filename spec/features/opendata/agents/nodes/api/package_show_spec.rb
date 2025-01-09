require 'spec_helper'

describe "opendata_agents_nodes_api", type: :feature, dbscope: :example do
  let!(:node) { create_once :opendata_node_api, name: "opendata_api" }
  let!(:node_dataset) { create_once :opendata_node_dataset }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, filename: "dataset/search" }

  let!(:dataset1) { create(:opendata_dataset, cur_node: node_dataset) }
  let!(:dataset2) { create(:opendata_dataset, cur_node: node_dataset) }
  let!(:dataset3) { create(:opendata_dataset, cur_node: node_dataset) }

  context "package_show" do
    context "no id" do
      let(:path) { "#{node.full_url}1/package_show" }

      it do
        visit path
        json = JSON.parse(html)
        expect(json["success"]).to be false
        expect(json["error"]["id"]).to eq "Missing value"
      end
    end

    context "id given" do
      context "dataset1 uuid" do
        let(:path) { "#{node.full_url}1/package_show?id=#{dataset1.uuid}" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]["name"]).to eq dataset1.name
          expect(json["result"]["uuid"]).to eq dataset1.uuid
        end
      end

      context "dataset2 uuid" do
        let(:path) { "#{node.full_url}1/package_show?id=#{dataset2.uuid}" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be true
          expect(json["result"]["name"]).to eq dataset2.name
          expect(json["result"]["uuid"]).to eq dataset2.uuid
        end
      end

      context "invalid" do
        let(:path) { "#{node.full_url}1/package_show?id=#{SecureRandom.uuid}" }

        it do
          visit path
          json = JSON.parse(html)
          expect(json["success"]).to be false
          expect(json["error"]["message"]).to eq "Not found"
        end
      end
    end
  end
end
