require 'spec_helper'

describe Cms::Addon::List::Model do
  let(:site) { cms_site }

  describe "#public_list" do
    let!(:form) { create :cms_form, cur_site: site, state: "public", sub_type: "entry" }
    let!(:column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form, order: 1, required: "optional", input_type: 'text')
    end
    let!(:column2) do
      create(:cms_column_date_field, cur_site: site, cur_form: form, order: 2, required: "optional")
    end
    let!(:column3) do
      create(:cms_column_check_box, cur_site: site, cur_form: form, order: 3, required: "optional", select_option_count: 5)
    end
    let!(:column4) do
      create(:cms_column_radio_button, cur_site: site, cur_form: form, order: 4, required: "optional", select_option_count: 5)
    end
    let!(:column5) do
      create(:cms_column_select, cur_site: site, cur_form: form, order: 5, required: "optional", select_option_count: 5)
    end
    let(:column1_value1) { unique_id * 2 }
    let(:column1_value2) { unique_id * 2 }
    let(:column2_value1) { "2019/10/12" }
    let(:column2_value2) { "2019/10/13" }
    let(:column3_values1) { column3.select_options.sample(2) }
    let(:column3_values2) { (column3.select_options - column3_values1).sample(2) }
    let(:column4_value1) { column4.select_options.sample }
    let(:column4_value2) { (column4.select_options - [ column4_value1 ]).sample }
    let(:column5_value1) { column5.select_options.sample }
    let(:column5_value2) { (column5.select_options - [ column5_value1 ]).sample }

    let!(:node) { create :article_node_page, cur_site: site }
    let!(:page1) do
      create(
        :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
        column_values: [
          column1.value_type.new(column: column1, value: column1_value1),
          column2.value_type.new(column: column2, date: column2_value1)
        ]
      )
    end
    let!(:page2) do
      create(
        :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
        column_values: [
          column2.value_type.new(column: column2, date: column2_value2),
          column3.value_type.new(column: column3, values: column3_values1)
        ]
      )
    end
    let!(:page3) do
      create(
        :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
        column_values: [
          column3.value_type.new(column: column3, values: column3_values2),
          column4.value_type.new(column: column4, value: column4_value1)
        ]
      )
    end
    let!(:page4) do
      create(
        :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
        column_values: [
          column4.value_type.new(column: column4, value: column4_value2),
          column5.value_type.new(column: column5, value: column5_value1)
        ]
      )
    end
    let!(:page5) do
      create(
        :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
        column_values: [
          column5.value_type.new(column: column5, value: column5_value2),
          column1.value_type.new(column: column1, value: column1_value2),
        ]
      )
    end
    let!(:page6) do
      create(
        :article_page, cur_site: site, cur_node: node, form: nil, state: 'public', html: "<p>#{unique_id}</p>"
      )
    end

    before do
      node.st_form_ids = [ form.id ]
      node.save!
    end

    subject { Article::Page.public_list(site: site, node: node).pluck(:id) }

    context "without condition_forms" do
      it do
        expect(subject).to have(6).items
        expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id, page6.id)
      end
    end

    context "with only form" do
      before do
        node.condition_forms = [{ form_id: form.id }]
        node.save!
      end

      it do
        expect(subject).to have(5).items
        expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
      end
    end

    context "with one filter" do
      before do
        node.condition_forms = [
          {
            form_id: form.id,
            filters: [{ column_id: column_id, condition_kind: condition_kind, condition_values: condition_values }]
          }
        ]
        node.save!
      end

      context "with 'any_of'" do
        let(:condition_kind) { 'any_of' }

        context "with single value on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page1.id)
          end
        end

        context "with multiple values on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1, column1_value2 ] }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page1.id, page5.id)
          end
        end

        context "with single value on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value2 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page2.id)
          end
        end

        context "with multiple value on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value1, column2_value2 ] }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page1.id, page2.id)
          end
        end

        context "with invalid date on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column1_value1 ] }

          it do
            expect(subject).to have(0).items
          end
        end

        context "with single value on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) { [ column3_values2.sample ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page3.id)
          end
        end

        context "with multiple values on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) { [ column3_values1.sample, column3_values2.sample ] }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page2.id, page3.id)
          end
        end

        context "with single value on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value2 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page4.id)
          end
        end

        context "with multiple values on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value1, column4_value2 ] }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page3.id, page4.id)
          end
        end

        context "with single value on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value2 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page5.id)
          end
        end

        context "with multiple values on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value1, column5_value2 ] }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page4.id, page5.id)
          end
        end
      end

      context "with 'none_of'" do
        let(:condition_kind) { 'none_of' }

        context "with single value on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page5.id)
          end
        end

        context "with multiple values on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1, column1_value2 ] }

          it do
            expect(subject).to have(0).items
          end
        end

        context "with single value on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value2 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page1.id)
          end
        end

        context "with multiple values on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value1, column2_value2 ] }

          it do
            expect(subject).to have(0).items
          end
        end

        context "with invalid date on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column1_value1 ] }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page1.id, page2.id)
          end
        end

        context "with single value on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) { [ column3_values2.sample ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page2.id)
          end
        end

        context "with multiple values on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) { [ column3_values1.sample, column3_values2.sample ] }

          it do
            expect(subject).to have(0).items
          end
        end

        context "with single value on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value2 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page3.id)
          end
        end

        context "with multiple values on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value1, column4_value2 ] }

          it do
            expect(subject).to have(0).items
          end
        end

        context "with single value on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value2 ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page4.id)
          end
        end

        context "with multiple values on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value1, column5_value2 ] }

          it do
            expect(subject).to have(0).items
          end
        end
      end

      context "with 'start_with'" do
        let(:condition_kind) { 'start_with' }

        context "with single value on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1.then { |str| str.slice(0, str.length / 2) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page1.id)
          end
        end

        context "with multiple values on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1, column1_value2 ].map { |str| str.slice(0, str.length / 2) } }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page1.id, page5.id)
          end
        end

        context "with single value on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value2 ] }

          it do
            # operator "start_with" on date_field is just ignored.
            # so you can see matching all pages with form
            expect(subject).to have(5).items
            expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
          end
        end

        context "with multiple values on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value1, column2_value2 ] }

          it do
            # operator "start_with" on date_field is just ignored.
            # so you can see matching all pages with form
            expect(subject).to have(5).items
            expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
          end
        end

        context "with invalid date on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column1_value1.then { |str| str.slice(0, str.length / 2) } ] }

          it do
            # operator "start_with" on date_field is just ignored.
            # so you can see matching all pages with form
            expect(subject).to have(5).items
            expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
          end
        end

        context "with single value on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) { [ column3_values2.sample.then { |str| str.slice(0, str.length / 2) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page3.id)
          end
        end

        context "with multiple values on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) do
            [ column3_values1.sample, column3_values2.sample ].map { |str| str.slice(0, str.length / 2) }
          end

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page2.id, page3.id)
          end
        end

        context "with single value on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value2.then { |str| str.slice(0, str.length / 2) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page4.id)
          end
        end

        context "with multiple values on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value1, column4_value2 ].map { |str| str.slice(0, str.length / 2) } }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page3.id, page4.id)
          end
        end

        context "with single value on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value2.then { |str| str.slice(0, str.length / 2) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page5.id)
          end
        end

        context "with multiple values on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value1, column5_value2 ].map { |str| str.slice(0, str.length / 2) } }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page4.id, page5.id)
          end
        end
      end

      context "with 'end_with'" do
        let(:condition_kind) { 'end_with' }

        context "with single value on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1.then { |str| str.slice(str.length / 2, str.length) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page1.id)
          end
        end

        context "with multiple values on text_field" do
          let(:column_id) { column1.id }
          let(:condition_values) { [ column1_value1, column1_value2 ].map { |str| str.slice(str.length / 2, str.length) } }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page1.id, page5.id)
          end
        end

        context "with single value on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value2 ] }

          it do
            # operator "end_with" on date_field is just ignored.
            # so you can see matching all pages with form
            expect(subject).to have(5).items
            expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
          end
        end

        context "with multiple values on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column2_value1, column2_value2 ] }

          it do
            # operator "end_with" on date_field is just ignored.
            # so you can see matching all pages with form
            expect(subject).to have(5).items
            expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
          end
        end

        context "with invalid date on date_field" do
          let(:column_id) { column2.id }
          let(:condition_values) { [ column1_value1.then { |str| str.slice(str.length / 2, str.length) } ] }

          it do
            # operator "end_with" on date_field is just ignored.
            # so you can see matching all pages with form
            expect(subject).to have(5).items
            expect(subject).to include(page1.id, page2.id, page3.id, page4.id, page5.id)
          end
        end

        context "with single value on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) { [ column3_values2.sample.then { |str| str.slice(str.length / 2, str.length) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page3.id)
          end
        end

        context "with multiple values on check_box" do
          let(:column_id) { column3.id }
          let(:condition_values) do
            [ column3_values1.sample, column3_values2.sample ].map { |str| str.slice(str.length / 2, str.length) }
          end

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page2.id, page3.id)
          end
        end

        context "with single value on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value2.then { |str| str.slice(str.length / 2, str.length) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page4.id)
          end
        end

        context "with multiple values on radio_button" do
          let(:column_id) { column4.id }
          let(:condition_values) { [ column4_value1, column4_value2 ].map { |str| str.slice(str.length / 2, str.length) } }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page3.id, page4.id)
          end
        end

        context "with single value on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value2.then { |str| str.slice(str.length / 2, str.length) } ] }

          it do
            expect(subject).to have(1).items
            expect(subject).to include(page5.id)
          end
        end

        context "with multiple values on select" do
          let(:column_id) { column5.id }
          let(:condition_values) { [ column5_value1, column5_value2 ].map { |str| str.slice(str.length / 2, str.length) } }

          it do
            expect(subject).to have(2).items
            expect(subject).to include(page4.id, page5.id)
          end
        end
      end
    end

    context "with two filter" do
      before do
        node.condition_forms = [
          {
            form_id: form.id,
            filters: [
              { column_id: column_id1, condition_kind: condition_kind1, condition_values: condition_values1 },
              { column_id: column_id2, condition_kind: condition_kind2, condition_values: condition_values2 }
            ]
          }
        ]
        node.save!
      end

      context "on same column; no result" do
        let(:column_id1) { column1.id }
        let(:condition_kind1) { %w(any_of start_with end_with).sample }
        let(:condition_values1) { [ column1_value1 ] }

        let(:column_id2) { column1.id }
        let(:condition_kind2) { (%w(any_of start_with end_with) - [ condition_kind1 ]).sample }
        let(:condition_values2) { [ column1_value2 ] }

        it do
          expect(subject).to have(0).items
          # expect(subject).to include(page1.id, page5.id)
        end
      end

      context "on different columns; this is expected case" do
        let(:column_id1) { column4.id }
        let(:condition_kind1) { %w(any_of start_with end_with).sample }
        let(:condition_values1) { [ column4_value2 ] }

        let(:column_id2) { column5.id }
        let(:condition_kind2) { (%w(any_of start_with end_with) - [ condition_kind1 ]).sample }
        let(:condition_values2) { [ column5_value1 ] }

        it do
          expect(subject).to have(1).items
          expect(subject).to include(page4.id)
        end
      end

      context "on different columns; no result" do
        let(:column_id1) { column1.id }
        let(:condition_kind1) { %w(any_of start_with end_with).sample }
        let(:condition_values1) { [ column1_value1 ] }

        let(:column_id2) { column4.id }
        let(:condition_kind2) { (%w(any_of start_with end_with) - [ condition_kind1 ]).sample }
        let(:condition_values2) { [ column4_value2 ] }

        it do
          expect(subject).to have(0).items
        end
      end
    end
  end

  # condition_forms は、編集時の形式と内部表現とが大きく異なる。そのテスト。
  describe "input and output" do
    let!(:form1) { create :cms_form, cur_site: site, state: "public", sub_type: "entry" }
    let!(:form2) { create :cms_form, cur_site: site, state: "public", sub_type: "entry" }

    context "when only form_ids are given" do
      it do
        node = build(:article_node_page, cur_site: site)
        node.condition_forms = {
          "form_ids" => [ "", form1.id.to_s, form2.id.to_s ]
        }
        node.save!

        # reload from database
        node = Article::Node::Page.find(node.id)

        expect(node.condition_forms.count).to eq 2
        node.condition_forms[0].tap do |condition_form|
          expect(condition_form.form_id).to eq form1.id
          expect(condition_form.filters).to be_blank
        end
        node.condition_forms[1].tap do |condition_form|
          expect(condition_form.form_id).to eq form2.id
          expect(condition_form.filters).to be_blank
        end
      end
    end

    context "when filters are given" do
      context "when there are columns having same name in multiple forms" do
        let!(:form1_column1) do
          create(:cms_column_text_field, cur_site: site, cur_form: form1, required: "optional", input_type: 'text')
        end
        let!(:form1_column2) do
          create(:cms_column_text_field, cur_site: site, cur_form: form1, required: "optional", input_type: 'text')
        end
        let!(:form2_column1) do
          create(:cms_column_text_field, cur_site: site, cur_form: form2, required: "optional", input_type: 'text')
        end
        let!(:form2_column2) do
          create(:cms_column_text_field, cur_site: site, cur_form: form2, required: "optional", input_type: 'text')
        end
        let(:condition_values1) { [ unique_id, unique_id ] }
        let(:condition_values2) { [ unique_id, unique_id ] }

        it do
          node = build(:article_node_page, cur_site: site)
          node.condition_forms = {
            "form_ids" => [ "", form1.id.to_s, form2.id.to_s ],
            "filters" => [
              { "column_name" => form1_column1.name, "condition_values" => condition_values1.join(", ") },
              { "column_name" => form1_column2.name, "condition_values" => condition_values2.join(", ") },
            ]
          }
          node.save!

          expect(node.condition_forms.count).to eq 2
          node.condition_forms[0].tap do |condition_form|
            expect(condition_form.form_id).to eq form1.id
            expect(condition_form.filters.count).to eq 2
            condition_form.filters[0].tap do |filter|
              expect(filter.column_id).to eq form1_column1.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values).to eq condition_values1
            end
            condition_form.filters[1].tap do |filter|
              expect(filter.column_id).to eq form1_column2.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values).to eq condition_values2
            end
          end
          node.condition_forms[1].tap do |condition_form|
            expect(condition_form.form_id).to eq form2.id
            expect(condition_form.filters).to be_blank
          end
        end
      end

      context "when there are columns having same name in multiple forms" do
        let!(:form1_column1) do
          create(:cms_column_text_field, cur_site: site, cur_form: form1, required: "optional", input_type: 'text')
        end
        let!(:form1_column2) do
          create(:cms_column_text_field, cur_site: site, cur_form: form1, required: "optional", input_type: 'text')
        end
        let!(:form2_column1) do
          create(
            :cms_column_text_field, cur_site: site, cur_form: form2, name: form1_column1.name,
            required: "optional", input_type: 'text'
          )
        end
        let!(:form2_column2) do
          create(
            :cms_column_text_field, cur_site: site, cur_form: form2, name: form1_column2.name,
            required: "optional", input_type: 'text'
          )
        end
        let(:condition_values1) { [ unique_id, unique_id ] }
        let(:condition_values2) { [ unique_id, unique_id ] }

        it do
          node = build(:article_node_page, cur_site: site)
          node.condition_forms = {
            "form_ids" => [ "", form1.id.to_s, form2.id.to_s ],
            "filters" => [
              { "column_name" => form1_column1.name, "condition_values" => condition_values1.join(", ") },
              { "column_name" => form1_column2.name, "condition_values" => condition_values2.join(", ") },
            ]
          }
          node.save!

          expect(node.condition_forms.count).to eq 2
          node.condition_forms[0].tap do |condition_form|
            expect(condition_form.form_id).to eq form1.id
            expect(condition_form.filters.count).to eq 2
            condition_form.filters[0].tap do |filter|
              expect(filter.column_id).to eq form1_column1.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values.length).to eq 2
            end
            condition_form.filters[1].tap do |filter|
              expect(filter.column_id).to eq form1_column2.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values.length).to eq 2
            end
          end
          node.condition_forms[1].tap do |condition_form|
            expect(condition_form.form_id).to eq form2.id
            expect(condition_form.filters.count).to eq 2
            condition_form.filters[0].tap do |filter|
              expect(filter.column_id).to eq form2_column1.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values.length).to eq 2
            end
            condition_form.filters[1].tap do |filter|
              expect(filter.column_id).to eq form2_column2.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values.length).to eq 2
            end
          end
        end
      end

      context "when there are multiple filters on a same column" do
        let!(:form1_column1) do
          create(:cms_column_text_field, cur_site: site, cur_form: form1, required: "optional", input_type: 'text')
        end
        let!(:form1_column2) do
          create(:cms_column_text_field, cur_site: site, cur_form: form1, required: "optional", input_type: 'text')
        end
        let(:condition_value1) { unique_id }
        let(:condition_value2) { unique_id }
        let(:condition_value3) { unique_id }
        let(:condition_values1) { [ "", condition_value1, condition_value2 ] }
        let(:condition_values2) { [ condition_value2, condition_value3 ] }

        it do
          node = build(:article_node_page, cur_site: site)
          node.condition_forms = {
            "form_ids" => [ "", form1.id.to_s, form2.id.to_s ],
            "filters" => [
              { "column_name" => form1_column1.name, "condition_values" => condition_values1.join(", ") },
              { "column_name" => form1_column1.name, "condition_values" => condition_values2.join(", ") },
            ]
          }
          node.save!

          expect(node.condition_forms.count).to eq 2
          node.condition_forms[0].tap do |condition_form|
            expect(condition_form.form_id).to eq form1.id
            expect(condition_form.filters.count).to eq 1
            condition_form.filters[0].tap do |filter|
              expect(filter.column_id).to eq form1_column1.id
              expect(filter.condition_kind).to eq "any_of"
              expect(filter.condition_values.count).to eq 3
              expect(filter.condition_values).to include(condition_value1, condition_value2, condition_value3)
            end
          end
          node.condition_forms[1].tap do |condition_form|
            expect(condition_form.form_id).to eq form2.id
            expect(condition_form.filters).to be_blank
          end
        end
      end
    end
  end
end
