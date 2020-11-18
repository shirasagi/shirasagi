require 'spec_helper'

describe Member::Node::Login, type: :model, dbscope: :example do
  describe "#redirect_full_url" do
    let(:site) { cms_site }

    context "when redirect_url is missing" do
      let(:node) { create :member_node_login, cur_site: site, redirect_url: nil }
      it do
        expect(node.redirect_full_url).to be_blank
      end
    end

    context "when redirect_url is full path" do
      let(:node) { create :member_node_login, cur_site: site, redirect_url: "/#{unique_id}" }
      it do
        expect(node.redirect_full_url).to eq URI.join(node.site.full_url, node.redirect_url).to_s
      end
    end

    context "when redirect_url is full url" do
      let(:node) { create :member_node_login, cur_site: site, redirect_url: "#{site.full_url}#{unique_id}" }
      it do
        expect(node.redirect_full_url).to eq URI.join(node.site.full_url, node.redirect_url).to_s
      end
    end

    context "when redirect_url is other site url" do
      let(:node) { create :member_node_login, cur_site: site, redirect_url: unique_url }
      it do
        expect(node.redirect_full_url).to be_blank
      end
    end
  end

  describe "#make_trusted_full_url" do
    let(:site) { cms_site }
    let(:node) { create :member_node_login, cur_site: site }

    context "when nil is given" do
      it do
        expect(node.make_trusted_full_url(nil)).to be_blank
      end
    end

    context "when empty string is given" do
      it do
        expect(node.make_trusted_full_url("")).to be_blank
      end
    end

    context "when full path is given" do
      let(:path) { "/#{unique_id}" }
      it do
        expect(node.make_trusted_full_url(path)).to eq URI.join(node.site.full_url, path[1..-1]).to_s
      end
    end

    context "when full url is given" do
      let(:url) { "#{site.full_url}#{unique_id}" }
      it do
        expect(node.make_trusted_full_url(url)).to eq url
      end
    end

    context "when other site url is given" do
      let(:url) { unique_url }
      it do
        expect(node.make_trusted_full_url(url)).to be_blank
      end
    end
  end
end
