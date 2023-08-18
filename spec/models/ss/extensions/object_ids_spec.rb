require 'spec_helper'

describe SS::Extensions::ObjectIds, type: :model, dbscope: :example do
  describe ".demongoize" do
    context "when nil is given" do
      subject { described_class.demongoize(nil) }

      it do
        # expect(subject).to be_nil
        expect(subject).to be_a(described_class)
        expect(subject).to have(0).items
      end
    end

    context "when empty array is given" do
      subject { described_class.demongoize([]) }

      it do
        expect(subject).to be_a(described_class)
        expect(subject).to have(0).items
      end
    end

    context "when int array is given" do
      let(:id) { rand(0..100) }
      subject { described_class.demongoize([ id ]) }

      it do
        expect(subject).to be_a(described_class)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(Integer)
        expect(subject[0]).to eq id
      end
    end

    context "when int-string array is given" do
      let(:id) { rand(0..100) }
      subject { described_class.demongoize([ id.to_s ]) }

      it do
        expect(subject).to be_a(described_class)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(String)
        expect(subject[0]).to eq id.to_s
      end
    end

    context "when BSON::ObjectId array is given" do
      let(:id) { BSON::ObjectId.new }
      subject { described_class.demongoize([ id ]) }

      it do
        expect(subject).to be_a(described_class)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(BSON::ObjectId)
        expect(subject[0]).to eq id
      end
    end
  end

  describe ".mongoize" do
    context "when nil is given" do
      subject { described_class.mongoize(nil) }

      it do
        expect(subject).to be_nil
      end
    end

    context "when empty string is given" do
      subject { described_class.mongoize('') }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(0).items
      end
    end

    context "when arbitrary string is given" do
      let(:id) { unique_id }
      subject { described_class.mongoize(id) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(String)
        expect(subject[0]).to eq id
      end
    end

    context "when int is given" do
      let(:id) { rand(0..100) }
      subject { described_class.mongoize(id) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(Integer)
        expect(subject[0]).to eq id
      end
    end

    context "when int array is given" do
      let(:id) { rand(0..100) }
      subject { described_class.mongoize([ id ]) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(Integer)
        expect(subject[0]).to eq id
      end
    end

    context "when BSON::ObjectId array is given" do
      let(:id) { BSON::ObjectId.new }
      subject { described_class.mongoize([ id ]) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(String)
        expect(subject[0]).to eq id.to_s
      end
    end

    context "when int-string array is given" do
      let(:id) { rand(0..100) }
      subject { described_class.mongoize([ id.to_s ]) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(Integer)
        expect(subject[0]).to eq id
      end
    end

    context "when BSON::ObjectId-string array is given" do
      let(:id) { BSON::ObjectId.new }
      subject { described_class.mongoize([ id.to_s ]) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(String)
        expect(subject[0]).to eq id.to_s
      end
    end

    context "when numeric like BSON::ObjectId-string array is given" do
      let(:id) { '613050552990e51668603266' }
      subject { described_class.mongoize([ id ]) }

      it do
        expect(subject).to be_a(Array)
        expect(subject).to have(1).items
        expect(subject[0]).to be_a(String)
        expect(subject[0]).to eq id
      end
    end
  end
end
