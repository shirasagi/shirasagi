require 'spec_helper'

describe Cms::User do
  let(:model) { Cms::User }
  let(:group1) { create(:cms_group, name: unique_id) }
  let(:group2) { create(:cms_group, name: unique_id) }
  let(:site1) { create(:cms_site, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: [ group1.id ]) }
  let(:site2) { create(:cms_site, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: [ group2.id ]) }

  after :all do
    group1.delete if group1.present?
    group2.delete if group2.present?
    site1.delete if site1.present?
    site2.delete if site2.present?
  end

  describe "#save" do
    context "when sns user is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          email: "u#{unique_id}@example.jp",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "sns",
          group_ids: [ group1.id ]
        }
      end
      it "saves successfully" do
        expect(model.new(entity).save).to eq true
      end
      it "finds successfully" do
        expect(model.where(email: entity[:email])).not_to be_nil
      end
    end

    context "when ldap user is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "sns",
          group_ids: [ group1.id ],
          accounts: [ { uid: "u#{unique_id}", group_id: group1.id } ],
          ldap_dn: "dc=example,dc=jp"
        }
      end
      it "saves successfully" do
        expect(model.new(entity).save).to eq true
      end
      it "finds successfully" do
        expect(model.where("accounts.uid" => entity[:accounts][0][:uid],
                           "accounts.group_id" => entity[:accounts][0][:group_id])).not_to be_nil
      end
    end
  end

  describe "#long_name" do
    context "when email(sns user) is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          email: "u#{unique_id}@example.jp",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "sns",
          group_ids: [ group1.id ]
        }
      end
      subject(:item) { model.create!(entity) }
      it { expect(subject.long_name).to eq "#{subject.name}(#{subject.email.split("@")[0]})" }
    end

    context "when uid(ldap user) is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "ldap",
          group_ids: [ group1.id ],
          accounts: [ { uid: "u#{unique_id}", group_id: group1.id },
                      { uid: "u#{unique_id}", group_id: group2.id } ],
          ldap_dn: "dc=example,dc=jp"
        }
      end

      context "when site1 is given" do
        subject(:item) { model.create!(entity) }
        it do
          subject.cur_site = site1
          expect(subject.long_name).to eq "#{subject.name}(#{subject.accounts[0].uid})"
        end
      end

      context "when site2 is given" do
        subject(:item) { model.create!(entity) }
        it do
          subject.cur_site = site2
          expect(subject.long_name).to eq "#{subject.name}(#{subject.accounts[1].uid})"
        end
      end

      context "when cur_site is not given" do
        subject(:item) { model.create!(entity) }
        it do
          expect(subject.long_name).to eq "#{subject.name}"
        end
      end
    end
  end

  describe "#set_in_uid and #in_uid" do
    context "when email(sns user) is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          email: "u#{unique_id}@example.jp",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "sns",
          group_ids: [ group1.id ]
        }
      end
      subject(:item) { model.create!(entity) }
      it do
        expect(subject.in_uid).to be_nil
      end
    end

    context "when uid(ldap user) is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "ldap",
          group_ids: [ group1.id ],
          accounts: [ { uid: "u#{unique_id}", group_id: group1.id },
                      { uid: "u#{unique_id}", group_id: group2.id } ],
          ldap_dn: "dc=example,dc=jp"
        }
      end

      context "when site1 is given" do
        subject(:item) { model.create!(entity) }
        it do
          subject.cur_site = site1
          expect(subject.in_uid).to eq "#{subject.accounts[0].uid}"
        end
      end

      context "when site2 is given" do
        subject(:item) { model.create!(entity) }
        it do
          subject.cur_site = site2
          expect(subject.in_uid).to eq "#{subject.accounts[1].uid}"
        end
      end

      context "when site is not given" do
        subject(:item) { model.create!(entity) }
        it do
          expect(subject.in_uid).to be_nil
        end
      end
    end
  end

  describe "#save with in_uid" do
    context "when uid(ldap user) is given" do
      subject(:entity) do
        {
          name: "u#{unique_id}",
          password: SS::Crypt.crypt("p#{unique_id}"),
          type: "ldap",
          group_ids: [ group1.id ],
          accounts: [ { uid: "u#{unique_id}", group_id: group1.id },
                      { uid: "u#{unique_id}", group_id: group2.id } ],
          ldap_dn: "dc=example,dc=jp"
        }
      end

      context "when site1 is given" do
        subject(:item) { model.new(entity) }
        it do
          expected = { uid: unique_id, group_id: group1.id }
          subject.cur_site = site1
          subject.in_uid = expected[:uid]
          expect { subject.save! }.not_to raise_error
          expect(subject.accounts.length).to eq entity[:accounts].length
          expect(subject.accounts).to include(SS::User::Model::Account.new(expected))
          expect(subject.accounts).not_to include(SS::User::Model::Account.new(entity[:accounts][0]))
          expect(subject.accounts).to include(SS::User::Model::Account.new(entity[:accounts][1]))
        end
      end

      context "when site2 is given" do
        subject(:item) { model.new(entity) }
        it do
          expected = { uid: unique_id, group_id: group2.id }
          subject.cur_site = site2
          subject.in_uid = expected[:uid]
          expect { subject.save! }.not_to raise_error
          expect(subject.accounts.length).to eq entity[:accounts].length
          expect(subject.accounts).to include(SS::User::Model::Account.new(expected))
          expect(subject.accounts).to include(SS::User::Model::Account.new(entity[:accounts][0]))
          expect(subject.accounts).not_to include(SS::User::Model::Account.new(entity[:accounts][1]))
        end
      end
    end
  end
end
