require 'spec_helper'

describe Cms::Member, dbscope: :example do
  context "when empty email member is given" do
    context "when oauth_type is not given" do
      subject { attributes_for(:cms_member, email: "") }
      it { expect { described_class.create! subject }.to raise_error Mongoid::Errors::Validations }
    end

    context "when oauth_type is given" do
      subject { attributes_for(:cms_member, email: "", oauth_type: "facebook") }
      it do
        expect { described_class.create! subject }.not_to raise_error
        expect(described_class.first.has_attribute?(:email)).to be_falsey
      end
    end

    context "when two member having oauth_type is given" do
      let(:member1) { attributes_for(:cms_member, email: "", oauth_type: "facebook") }
      let(:member2) { attributes_for(:cms_member, email: "", oauth_type: "github") }
      it do
        expect { described_class.create! member1 }.not_to raise_error
        expect { described_class.create! member2 }.not_to raise_error
        expect(described_class.where(name: member1[:name]).first.has_attribute?(:email)).to be_falsey
        expect(described_class.where(name: member2[:name]).first.has_attribute?(:email)).to be_falsey
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

  describe ".name_of" do
    it "returns name" do
      info = OmniAuth::AuthHash::InfoHash.new
      info[:name] = "name"
      info[:nickname] = "nickname"
      expect(described_class.name_of(info)).to eq "name"
    end

    it "returns first_name" do
      info = OmniAuth::AuthHash::InfoHash.new
      info[:name] = ""
      info[:first_name] = "first_name"
      expect(described_class.name_of(info)).to eq "first_name"
    end

    it "returns last_name" do
      info = OmniAuth::AuthHash::InfoHash.new
      info[:name] = ""
      info[:last_name] = "last_name"
      expect(described_class.name_of(info)).to eq "last_name"
    end

    it "returns composite of first_name and last_name" do
      info = OmniAuth::AuthHash::InfoHash.new
      info[:name] = ""
      info[:first_name] = "first_name"
      info[:last_name] = "last_name"
      expect(described_class.name_of(info)).to eq "first_name last_name"
    end

    it "returns nickname" do
      # this example examines the github blank name issue.
      info = OmniAuth::AuthHash::InfoHash.new
      info[:name] = ""
      info[:nickname] = "nickname"
      expect(described_class.name_of(info)).to eq "nickname"
    end

    it "returns email" do
      # this example examines the github blank name issue.
      info = OmniAuth::AuthHash::InfoHash.new
      info[:name] = ""
      info[:email] = "address@example.jp"
      expect(described_class.name_of(info)).to eq "address"
    end
  end
end
