require 'spec_helper'

describe Cms::Line::Message, type: :model, dbscope: :example do
  let!(:deliver_category_first) do
    create(:cms_line_deliver_category_category, filename: "c1", select_type: "checkbox")
  end
  let!(:deliver_category_first1) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_first, filename: "1")
  end
  let!(:deliver_category_first2) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_first, filename: "2")
  end
  let!(:deliver_category_first3) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_first, filename: "3")
  end
  let!(:deliver_category_second) do
    create(:cms_line_deliver_category_category, filename: "c2", select_type: "checkbox")
  end
  let!(:deliver_category_second1) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_second, filename: "1")
  end
  let!(:deliver_category_second2) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_second, filename: "2")
  end
  let!(:deliver_category_second3) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_second, filename: "3")
  end

  # active members
  let!(:member1) { create(:cms_line_member) }
  let!(:member2) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category_first1.id])
  end
  let!(:member3) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category_first2.id])
  end
  let!(:member4) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category_first1.id, deliver_category_first3.id])
  end
  let!(:member5) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category_first2.id, deliver_category_first3.id, deliver_category_second1.id])
  end

  # expired members
  let!(:member6) { create(:cms_member, subscribe_line_message: "active") }
  let!(:member7) { create(:cms_line_member, subscribe_line_message: "expired") }
  let!(:member8) { create(:cms_line_member, subscribe_line_message: "active", state: "disabled") }

  def member_ids
    item.extract_deliver_members.map(&:id)
  end

  context do "multicast_with_no_condition"
    let!(:item) { create(:cms_line_message) }

    it do
      expect(member_ids).to match_array [member1.id, member2.id, member3.id, member4.id, member5.id]
    end
  end

  context do "multicast_with_registered_condition"
    let!(:deliver_condition) do
      create(:cms_line_deliver_condition,
        deliver_category_ids: [deliver_category_first1.id])
    end
    let!(:item) do
      create(:cms_line_message,
        deliver_condition_state: "multicast_with_registered_condition",
        deliver_condition_id: deliver_condition.id)
    end

    it do
      expect(member_ids).to match_array [member2.id, member4.id]
    end
  end

  context do "multicast_with_input_condition"
    context "deliver_category_first1" do
      let!(:item) do
        create(:cms_line_message,
          deliver_condition_state: "multicast_with_input_condition",
          deliver_category_ids: [deliver_category_first1.id])
      end

      it do
        expect(member_ids).to match_array [member2.id, member4.id]
      end
    end

    context "deliver_category_first1 or deliver_category_first2" do
      let!(:item) do
        create(:cms_line_message,
          deliver_condition_state: "multicast_with_input_condition",
          deliver_category_ids: [deliver_category_first1.id, deliver_category_first2.id])
      end

      it do
        expect(member_ids).to match_array [member2.id, member3.id, member4.id, member5.id]
      end
    end

    context "deliver_category_first3 and deliver_category_second1" do
      let!(:item) do
        create(:cms_line_message,
          deliver_condition_state: "multicast_with_input_condition",
          deliver_category_ids: [deliver_category_first3.id, deliver_category_second1.id])
      end

      it do
        expect(member_ids).to match_array [member5.id]
      end
    end

    context "validation" do
      it do
        item = build(:cms_line_message, deliver_condition_state: "multicast_with_input_condition")
        expect(item.valid?).to be_falsey
      end

      it do
        item = build(:cms_line_message, deliver_condition_state: "multicast_with_registered_condition")
        expect(item.valid?).to be_falsey
      end
    end
  end
end
