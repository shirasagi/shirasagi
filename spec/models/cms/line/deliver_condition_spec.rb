require 'spec_helper'

describe Cms::Line::DeliverCondition, type: :model, dbscope: :example do
  let!(:deliver_category1) do
    create(:cms_line_deliver_category_category, filename: "c1", select_type: "checkbox")
  end
  let!(:deliver_category1_1) do
    create(:cms_line_deliver_category_selection, parent: deliver_category1, filename: "1")
  end
  let!(:deliver_category1_2) do
    create(:cms_line_deliver_category_selection, parent: deliver_category1, filename: "2")
  end
  let!(:deliver_category1_3) do
    create(:cms_line_deliver_category_selection, parent: deliver_category1, filename: "3")
  end
  let!(:deliver_category2) do
    create(:cms_line_deliver_category_category, filename: "c2", select_type: "checkbox")
  end
  let!(:deliver_category2_1) do
    create(:cms_line_deliver_category_selection, parent: deliver_category2, filename: "1")
  end
  let!(:deliver_category2_2) do
    create(:cms_line_deliver_category_selection, parent: deliver_category2, filename: "2")
  end
  let!(:deliver_category2_3) do
    create(:cms_line_deliver_category_selection, parent: deliver_category2, filename: "3")
  end

  # active members
  let!(:member1) { create(:cms_line_member) }
  let!(:member2) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category1_1.id])
  end
  let!(:member3) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category1_2.id])
  end
  let!(:member4) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category1_1.id, deliver_category1_3.id])
  end
  let!(:member5) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category1_2.id, deliver_category1_3.id, deliver_category2_1.id])
  end

  # expired members
  let!(:member6) { create(:cms_member, subscribe_line_message: "active") }
  let!(:member7) { create(:cms_line_member, subscribe_line_message: "expired") }
  let!(:member8) { create(:cms_line_member, subscribe_line_message: "active", state: "disabled") }

  def member_ids
    item.extract_deliver_members.map(&:id)
  end

  context "deliver_category1_1" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        deliver_category_ids: [deliver_category1_1.id])
    end

    it do
      expect(member_ids).to match_array [member2.id, member4.id]
    end
  end

  context "deliver_category1_1 or deliver_category1_2" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        deliver_category_ids: [deliver_category1_1.id, deliver_category1_2.id])
    end

    it do
      expect(member_ids).to match_array [member2.id, member3.id, member4.id, member5.id]
    end
  end

  context "deliver_category1_3 and deliver_category2_1" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        deliver_category_ids: [deliver_category1_3.id, deliver_category2_1.id])
    end

    it do
      expect(member_ids).to match_array [member5.id]
    end
  end

  context "validation" do
    it do
      item = build(:cms_line_deliver_condition)
      expect(item.valid?).to be_falsey
    end
  end
end
