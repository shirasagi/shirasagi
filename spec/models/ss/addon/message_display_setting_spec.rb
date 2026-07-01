require 'spec_helper'

describe SS::Addon::MessageDisplaySetting, type: :model, dbscope: :example do
  let!(:group) { create(:ss_group) }
  let(:user) { create(:ss_user, group_ids: [ group.id ]) }

  # 本 PR の主契約: 未設定ユーザーは従来どおり「差出人 → 件名」のまま
  describe "default value" do
    it "defaults to name_first and is not subject-first for a new user" do
      expect(user.message_list_column_order).to eq "name_first"
      expect(user.message_list_subject_first?).to be_falsey
    end
  end

  describe "validation of message_list_column_order" do
    %w(name_first subject_first).each do |value|
      it "accepts #{value}" do
        expect(user.update(message_list_column_order: value)).to be_truthy
        expect(user.reload.message_list_column_order).to eq value
      end
    end

    it "rejects an unknown value" do
      expect(user.update(message_list_column_order: "unknown")).to be_falsey
      expect(user.errors[:message_list_column_order]).to be_present
    end

    # nil/空は許容し、初期値（差出人 → 件名）として扱う。
    # allow_blank により default 補完に依存せず、射影パス等で nil が来ても保存を弾かない。
    [nil, ""].each do |value|
      it "accepts #{value.inspect} as the initial value" do
        expect(user.update(message_list_column_order: value)).to be_truthy
        expect(user.reload.message_list_subject_first?).to be_falsey
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
