require 'spec_helper'

describe Cms::Line::DeliverCondition, type: :model, dbscope: :example do
  let!(:today) { Time.zone.today }

  let!(:birthday1) { today.advance(years: -1) }
  let!(:birthday2) { today.advance(years: -3) }
  let!(:birthday3) { today.advance(years: -5) }
  let!(:birthday4) { today.advance(months: -2) }
  let!(:birthday5) { today.advance(months: -10) }
  let!(:birthday6) { today.advance(months: 1) }

  let!(:in_birth1) { { era: "seireki", year: birthday1.year, month: birthday1.month, day: birthday1.day } }
  let!(:in_birth2) { { era: "seireki", year: birthday2.year, month: birthday2.month, day: birthday2.day } }
  let!(:in_birth3) { { era: "seireki", year: birthday3.year, month: birthday3.month, day: birthday3.day } }
  let!(:in_birth4) { { era: "seireki", year: birthday4.year, month: birthday4.month, day: birthday4.day } }
  let!(:in_birth5) { { era: "seireki", year: birthday5.year, month: birthday5.month, day: birthday5.day } }
  let!(:in_birth6) { { era: "seireki", year: birthday6.year, month: birthday6.month, day: birthday6.day } }

  let!(:deliver_category1) { create :cms_line_deliver_category_category }
  let!(:deliver_category1_1) { create :cms_line_deliver_category_category, parent: deliver_category1 }
  let!(:deliver_category1_2) { create :cms_line_deliver_category_category, parent: deliver_category1 }
  let!(:deliver_category1_3) { create :cms_line_deliver_category_category, parent: deliver_category1 }

  let!(:deliver_category2) { create :cms_line_deliver_category_category }
  let!(:deliver_category2_1) { create :cms_line_deliver_category_category, parent: deliver_category2 }
  let!(:deliver_category2_2) { create :cms_line_deliver_category_category, parent: deliver_category2 }
  let!(:deliver_category2_3) { create :cms_line_deliver_category_category, parent: deliver_category2 }

  # active members
  let!(:member1) { create(:cms_line_member) }
  let!(:member2) do
    create(:cms_line_member,
     child1_name: unique_id,
     in_child1_birth: in_birth1)
  end
  let!(:member3) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category1_1.id, deliver_category1_3.id])
  end
  let!(:member4) do
    create(:cms_line_member,
      child1_name: unique_id,
      child2_name: unique_id,
      in_child1_birth: in_birth2,
      in_child2_birth: in_birth3)
  end
  let!(:member5) do
    create(:cms_line_member,
      deliver_category_ids: [deliver_category1_2.id, deliver_category1_3.id, deliver_category2_1.id])
  end
  let!(:member6) do
    create(:cms_line_member,
      child1_name: unique_id,
      child2_name: unique_id,
      in_child1_birth: in_birth1,
      in_child2_birth: in_birth2,
      deliver_category_ids: [deliver_category2_1.id])
  end
  let!(:member7) do
    create(:cms_line_member,
      child1_name: unique_id,
      in_child1_birth: in_birth4)
  end
  let!(:member8) do
    create(:cms_line_member,
      child1_name: unique_id,
      in_child1_birth: in_birth5)
  end
  let!(:member9) do
    create(:cms_line_member,
      child1_name: unique_id,
      in_child1_birth: in_birth6)
  end

  # expired members
  let!(:member10) { create(:cms_member, subscribe_line_message: "active") }
  let!(:member11) { create(:cms_line_member, subscribe_line_message: "expired") }
  let!(:member12) { create(:cms_line_member, subscribe_line_message: "active", state: "disabled") }

  def member_ids
    item.extract_deliver_members.map(&:id)
  end

  context "year 1 ~ 1" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        lower_year1: 1,
        upper_year1: 1)
    end

    it do
      expect(member_ids).to match_array [member2.id, member6.id]
    end
  end

  context "year 2 ~ 3" do
    let!(:item) do
      create(:cms_line_deliver_condition,
       lower_year1: 2,
       upper_year1: 3)
    end

    it do
      expect(member_ids).to match_array [member4.id, member6.id]
    end
  end

  context "deliver_category1_1 or deliver_category1_2" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        deliver_category_ids: [deliver_category1_1.id, deliver_category1_2.id])
    end

    it do
      expect(member_ids).to match_array [member3.id, member5.id]
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

  context "year 2 ~ 3 and deliver_category2_1" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        lower_year1: 2,
        upper_year1: 3,
        deliver_category_ids: [deliver_category2_1.id])
    end

    it do
      expect(member_ids).to match_array [member6.id]
    end
  end

  context "month 0 ~ 6" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        lower_year1: 0,
        lower_month1: 0,
        upper_year1: 0,
        upper_month1: 6)
    end

    it do
      expect(member_ids).to match_array [member7.id]
    end
  end

  context "month 6 ~ 11" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        lower_year1: 0,
        lower_month1: 6,
        upper_year1: 0,
        upper_month1: 11)
    end

    it do
      expect(member_ids).to match_array [member8.id]
    end
  end

  context "year 0 ~ 1" do
    let!(:item) do
      create(:cms_line_deliver_condition,
        lower_year1: 0,
        upper_year1: 1)
    end

    it do
      expect(member_ids).to match_array [member2.id, member6.id, member7.id, member8.id]
    end
  end

  context "validation" do
    it do
      item = build(:cms_line_deliver_condition)
      expect(item.valid?).to be_falsey
    end
  end
end
