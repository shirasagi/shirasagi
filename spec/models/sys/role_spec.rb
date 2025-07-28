require 'spec_helper'

describe Sys::Role, dbscope: :example do
  subject(:model) { Sys::Role }
  subject(:factory) { :sys_role }

  it_behaves_like "mongoid#save"

  describe "#general?" do
    context "with edit_sys_groups" do
      subject! { create :sys_role, name: unique_id, permissions: [ "", "edit_sys_groups", "use_gws", nil ] }

      it do
        expect(subject.privileged?).to be_truthy
        expect(subject.general?).to be_falsey
        expect(described_class.all.count).to eq 1
        expect(described_class.all.and_general.count).to eq 0
      end
    end

    context "with use_cms" do
      subject! { create :sys_role, name: unique_id, permissions: [ nil, "use_cms", "use_gws", "use_webmail", "" ] }

      it do
        expect(subject.privileged?).to be_falsey
        expect(subject.general?).to be_truthy
        expect(described_class.all.count).to eq 1
        expect(described_class.all.and_general.count).to eq 1
      end
    end
  end
end
