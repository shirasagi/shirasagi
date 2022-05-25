require 'spec_helper'

describe Cms::Addon::List::Model do
  let(:site) { cms_site }
  let!(:form1) { create :cms_form, cur_site: site, state: "public", sub_type: "static" }
  let!(:form1_column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form1, order: 1, required: "optional", input_type: 'text')
  end
  let!(:form2) { create :cms_form, cur_site: site, state: "public", sub_type: "static" }
  let!(:form2_column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form2, order: 1, required: "optional", input_type: 'text')
  end

  let(:form1_column1_value1) { unique_id * 2 }
  let(:form1_column1_value2) { unique_id * 2 }
  let(:form2_column1_value1) { unique_id * 2 }
  let(:form2_column1_value2) { unique_id * 2 }

  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page1) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form1, state: 'public',
      column_values: [ form1_column1.value_type.new(column: form1_column1, value: form1_column1_value1) ]
    )
  end
  let!(:page2) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form1, state: 'public',
      column_values: [ form1_column1.value_type.new(column: form1_column1, value: form1_column1_value2) ]
    )
  end
  let!(:page3) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form2, state: 'public',
      column_values: [ form2_column1.value_type.new(column: form2_column1, value: form2_column1_value1) ]
    )
  end
  let!(:page4) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form2, state: 'public',
      column_values: [ form2_column1.value_type.new(column: form2_column1, value: form2_column1_value2) ]
    )
  end
  let!(:page_without_form) do
    create(
      :article_page, cur_site: site, cur_node: node, form: nil, state: 'public', html: "<p>#{unique_id}</p>"
    )
  end

  before do
    node.st_form_ids = [ form1.id, form2.id ]
    node.save!
  end

  describe "#public_list" do
    subject { Article::Page.public_list(site: site, node: node).pluck(:id) }

    context "without condition_forms" do
      it do
        expect(subject).to have(5).items
        expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page_without_form.id)
      end
    end

    context "with only form" do
      context "with form2" do
        before do
          node.condition_forms = [{ form_id: form2.id }]
          node.save!
        end

        it do
          expect(subject).to have(2).items
          expect(subject).to include(page3.id, page4.id)
        end
      end

      context "with form1 and form2" do
        before do
          node.condition_forms = [{ form_id: form1.id }, { form_id: form2.id }]
          node.save!
        end

        it do
          expect(subject).to have(4).items
          expect(subject).to include(page1.id, page2.id, page3.id, page4.id)
        end
      end
    end

    context "with filters" do
      before do
        node.condition_forms = [
          {
            form_id: form1.id,
            filters: [
              { column_id: form1_column1.id, condition_kind: form1_condition_kind, condition_values: form1_condition_values }
            ]
          },
          {
            form_id: form2.id,
            filters: [
              { column_id: form2_column1.id, condition_kind: form2_condition_kind, condition_values: form2_condition_values }
            ]
          }
        ]
        node.save!
      end

      context "with any_of" do
        let(:form1_condition_kind) { %w(any_of start_with end_with).sample }
        let(:form1_condition_values) { [ form1_column1_value1 ] }
        let(:form2_condition_kind) { %w(any_of start_with end_with).sample }
        let(:form2_condition_values) { [ form2_column1_value1 ] }

        it do
          expect(subject).to have(2).items
          expect(subject).to include(page1.id, page3.id)
        end
      end

      context "with none_of" do
        let(:form1_condition_kind) { "none_of" }
        let(:form1_condition_values) { [ form1_column1_value1 ] }
        let(:form2_condition_kind) { "none_of" }
        let(:form2_condition_values) { [ form2_column1_value1 ] }

        it do
          expect(subject).to have(2).items
          expect(subject).to include(page2.id, page4.id)
        end
      end
    end
  end
end
