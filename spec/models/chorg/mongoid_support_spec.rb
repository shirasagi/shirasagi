require 'spec_helper'

describe Chorg::MongoidSupport, dbscope: :example do
  let(:klass) { Struct.new("MongoidSupportClass#{unique_id.capitalize}") { include Chorg::MongoidSupport } }
  let(:support) { klass.new }

  describe "#group_field?" do
    let(:collect_fields) { ->(model) { model.fields.select { |k, v| support.group_field?(k, v) }.map { |k, _| k } } }

    context "with Cms::User" do
      subject { collect_fields.call(Cms::User) }
      it { expect(subject).to include("group_ids") }
    end

    context "with Article::Page" do
      subject { collect_fields.call(Article::Page) }
      it { expect(subject).to include("group_ids") }
      it { expect(subject).to include("contact_group_id") }
    end

    context "with Cms::Node" do
      subject { collect_fields.call(Cms::Node) }
      it { expect(subject).to include("group_ids") }
    end

    context "with Cms::User" do
      subject { collect_fields.call(Cms::User) }
      it { expect(subject).to include("group_ids") }
    end
  end
end
