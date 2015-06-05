require 'spec_helper'

describe Oauth::Twitter, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :member_node_login, site: cms_site }
  let(:app) { OpenStruct.new }
  let(:env) { OpenStruct.new("HTTP_HOST" => site.domain, "REQUEST_PATH" => node.url) }

  describe "#client_id" do
    subject { described_class.new app }

    before do
      subject.instance_variable_set(:@env, env)
    end

    its(:client_id) { is_expected.to eq node.twitter_client_id }
    its(:client_secret) { is_expected.to eq node.twitter_client_secret }
    its(:consumer) { is_expected.to be_a ::OAuth::Consumer }
  end
end
