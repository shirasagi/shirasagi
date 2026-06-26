require 'spec_helper'

describe SS::Addon::MessageDisplaySetting, type: :model, dbscope: :example do
  let!(:group) { create(:ss_group) }
  let(:user) { create(:ss_user, group_ids: [ group.id ]) }

  describe "validation of message_list_column_order" do
    %w(name_first subject_first).each do |value|
      it "accepts #{value}" do
        expect(user.update(message_list_column_order: value)).to be_truthy
        expect(user.reload.message_list_column_order).to eq value
      end
    end

    [nil, "", "unknown"].each do |value|
      it "rejects #{value.inspect}" do
        expect(user.update(message_list_column_order: value)).to be_falsey
        expect(user.errors[:message_list_column_order]).to be_present
      end
    end
  end

  describe "#message_list_subject_first?" do
    it "is true only when subject_first" do
      user.update!(message_list_column_order: "subject_first")
      expect(user.reload.message_list_subject_first?).to be_truthy

      user.update!(message_list_column_order: "name_first")
      expect(user.reload.message_list_subject_first?).to be_falsey
    end
  end
end
