require 'spec_helper'

describe Cms::User do
  let(:model) { Cms::User }
  let(:group1) { create(:cms_group, name: unique_id) }
  let(:group2) { create(:cms_group, name: unique_id) }
  let(:site1) { create(:cms_site, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: [ group1.id ]) }
  let(:site2) { create(:cms_site, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: [ group2.id ]) }

  describe "#save" do
    context "when sns user is given" do
      subject { attributes_for(:cms_user_base, :cms_user_rand_name, :cms_user_email, group: group1) }
      it "save and find successfully" do
        expect { model.new(subject).save! }.not_to raise_error
        expect(model.where(email: subject[:email]).first).not_to be_nil
        # uid can be nil if email.presents
        expect(model.where(email: subject[:email]).first.uid).to be_nil
      end
    end

    context "when ldap user is given" do
      subject { attributes_for(:cms_user_base, :cms_user_rand_name, :cms_user_uid, :cms_user_ldap, group: group1) }
      it "save and find successfully" do
        expect { model.new(subject).save! }.not_to raise_error
        expect(model.where(uid: subject[:uid]).first).not_to be_nil
        # email can be nil if uid.presents
        expect(model.where(uid: subject[:uid]).first.email).to be_nil
      end
    end

    context "when no email/uid is given" do
      subject { attributes_for(:cms_user_base, :cms_user_rand_name, group: group1) }
      it "save failed" do
        expect { model.new(subject).save! }.to raise_error Mongoid::Errors::Validations
      end
    end
  end

  describe "#long_name" do
    context "when email(sns user) is given" do
      subject { create(:cms_user_base, :cms_user_rand_name, :cms_user_email, group: group1) }
      it { expect(subject.long_name).to eq "#{subject.name}(#{subject.email.split("@")[0]})" }
    end

    context "when uid(ldap user) is given" do
      subject { create(:cms_user_base, :cms_user_rand_name, :cms_user_uid, group: group1) }
      it { expect(subject.long_name).to eq "#{subject.name}(#{subject.uid})" }
    end
  end
end
