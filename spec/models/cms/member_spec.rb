require 'spec_helper'

describe Cms::Member, dbscope: :example do
  context "when empty email member is given" do
    context "when oauth_type is not given" do
      subject { attributes_for(:cms_member, email: "") }
      it { expect { described_class.create! subject }.to raise_error Mongoid::Errors::Validations }
    end

    context "when oauth_type is given" do
      subject { attributes_for(:cms_member, email: "", oauth_type: "facebook") }
      it { expect { described_class.create! subject }.not_to raise_error }
    end

    context "when two member having oauth_type is given" do
      let(:member1) { attributes_for(:cms_member, email: "", oauth_type: "facebook") }
      let(:member2) { attributes_for(:cms_member, email: "", oauth_type: "github") }
      it do
        expect { described_class.create! member1 }.not_to raise_error
        expect { described_class.create! member2 }.not_to raise_error
      end
    end
  end

  describe ".create_auth_member" do
    let(:auth) do
      OpenStruct.new({ provider: "provider-#{unique_id}",
                       uid: "uid-#{unique_id}",
                       credentials: OpenStruct.new(token: "token-#{unique_id}"),
                       info: OpenStruct.new(name: "name-#{unique_id}") })
    end
    let(:site) { cms_site }

    it do
      expect { Cms::Member.create_auth_member(auth, site) }.to \
        change { Cms::Member.count }.from(0).to(1)
    end
  end
end
