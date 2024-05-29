require 'spec_helper'

describe Gws::User, dbscope: :example do
  let!(:site) { create :gws_group }
  let(:required_attrs) do
    { name: unique_id, in_password: "xyz", organization: site, group_ids: [ site.id ] }
  end

  describe "#uid" do
    context "with alphabets" do
      let(:uid) { "abcDEF" }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_valid
      end
    end

    context "with digits" do
      let(:uid) { "1234" }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_valid
      end
    end

    context "with hyphens" do
      let(:uid) { "abc-def-hij" }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_valid
      end
    end

    context "with underscores" do
      let(:uid) { "abc_def_hij" }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_valid
      end
    end

    context "with single period" do
      let(:uid) { "x.y" }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_valid
      end
    end

    context "with multiple periods" do
      let(:uid) { "x.y.z" }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_invalid
      end
    end

    context "end with period" do
      let(:uid) { "abc." }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_invalid
      end
    end

    context "with 64-length characters" do
      let(:uid) { Array.new(64) { ('a'..'z').to_a.sample }.join }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_valid
      end
    end

    context "with 65-length characters" do
      let(:uid) { Array.new(65) { ('a'..'z').to_a.sample }.join }

      it do
        user = Gws::User.new(uid: uid, **required_attrs)
        expect(user).to be_invalid
      end
    end
  end
end
