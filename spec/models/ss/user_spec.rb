require 'spec_helper'

describe SS::User do
  subject(:model) { SS::User }

  def raw_model(model, raw_query)
    val = model.collection.find(raw_query).first
    val.present? ? val.symbolize_keys : nil
  end

  describe "#save and #find" do
    subject(:factory) { :ss_user }
    it_behaves_like "mongoid#save"
    it_behaves_like "mongoid#find"
  end

  describe "#save" do
    subject(:group) { ss_group }

    context "when name is missing" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          email: "u#{r}@example.jp",
          password: SS::Crypt.crypt("p#{r}"),
          group_ids: [ group.id ]
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when uid and email is missing" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          name: "u#{r}",
          password: SS::Crypt.crypt("p#{r}"),
          group_ids: [ group.id ]
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when uid containing '@' is given" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          name: "u#{r}",
          password: SS::Crypt.crypt("p#{r}"),
          group_ids: [ group.id ],
          uid: "u#{r}@example.jp"
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when password is missing" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          name: "u#{r}",
          email: "u#{r}@example.jp",
          group_ids: [ group.id ]
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when invalid type is givin" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          name: "u#{r}",
          email: "u#{r}@example.jp",
          password: SS::Crypt.crypt("p#{r}"),
          type: "t#{r}",
          group_ids: [ group.id ]
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when two user having same email is given" do
      r0 = rand(0x100000000).to_s(36)
      r1= rand(0x100000000).to_s(36)
      r2 = rand(0x100000000).to_s(36)

      subject(:entity1) do
        {
          name: "u#{r1}",
          email: "u#{r0}@example.jp",
          password: SS::Crypt.crypt("p#{r1}"),
          group_ids: [ group.id ]
        }
      end
      subject(:entity2) do
        {
          name: "u#{r2}",
          email: "u#{r0}@example.jp",
          password: SS::Crypt.crypt("p#{r2}"),
          group_ids: [ group.id ]
        }
      end

      it do
        expect { model.new(entity1).save! }.not_to raise_error
        expect { model.new(entity2).save! }.to raise_error Mongoid::Errors::Validations
      end
    end

    context "when valid sns user is given" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          name: "u#{r}",
          email: "u#{r}@example.jp",
          password: SS::Crypt.crypt("p#{r}"),
          type: "sns",
          group_ids: [ group.id ]
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.not_to raise_error
      end
    end

    context "when valid ldap user is given" do
      r = rand(0x100000000).to_s(36)
      subject(:entity) do
        {
          name: "u#{r}",
          type: "ldap",
          group_ids: [ group.id ],
          uid: "u#{r}",
          ldap_dn: "cn=u#{r},dc=example,dc=jp"
        }
      end
      subject { model.new(entity) }

      it do
        expect { subject.save! }.not_to raise_error
      end
    end
  end
end
