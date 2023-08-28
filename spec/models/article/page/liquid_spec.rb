require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  describe "what article/page exports to liquid" do
    let(:assigns) { { "parts" => SS::LiquidPartDrop.get(cms_site) } }
    let(:registers) { { cur_site: cms_site, cur_node: node, cur_path: page.url } }
    subject { page.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "without form" do
      context "with Cms::Content" do
        let!(:released) { Time.zone.now.change(min: rand(0..59)) }
        let!(:page) { create :article_page, cur_node: node, index_name: unique_id, released: released }

        it do
          # Cms::Content
          expect(subject.id).to eq page.id
          expect(subject.name).to eq page.name
          expect(subject.index_name).to eq page.index_name
          expect(subject.url).to eq page.url
          expect(subject.full_url).to eq page.full_url
          expect(subject.basename).to eq page.basename
          expect(subject.filename).to eq page.filename
          expect(subject.order).to eq page.order
          expect(subject.date).to eq page.date
          expect(subject.released).to eq page.released
          expect(subject.updated).to eq page.updated
          expect(subject.created).to eq page.created
          expect(subject.parent.id).to eq node.id
          expect(subject.css_class).to eq page.basename.sub(".html", "").dasherize
          expect(subject.new?).to be_truthy
          expect(subject.current?).to be_truthy
        end
      end

      context "with Cms::Model::Page" do
        let!(:cate1) { create :category_node_page, name: "z", order: 10 }
        let!(:cate2) { create :category_node_page, name: "y", order: 20 }
        let!(:page) { create :article_page, cur_node: node, category_ids: [ cate1.id, cate2.id ] }

        it do
          # Cms::Model::Page
          expect(subject.categories.length).to eq 2
          expect(subject.categories.map(&:id)).to include(cate1.id, cate2.id)
        end
      end

      context "with Cms::Addon::Meta" do
        let(:summary) { Array.new(2) { "<p>#{unique_id}</p>" }.join("\n") }
        let(:description) { Array.new(2) { unique_id }.join("\n") }
        let!(:page) do
          create :article_page, cur_node: node, summary_html: summary, description: description
        end

        it do
          # Cms::Addon::Meta
          expect(subject.summary).to eq page.summary_html
          expect(subject.description).to eq description
        end
      end

      context "with Gravatar::Addon::Gravatar" do
        let!(:page) do
          create(
            :article_page, cur_node: node, gravatar_image_view_kind: "special_email",
            gravatar_email: "#{unique_id}@example.jp", gravatar_screen_name: unique_id
          )
        end

        it do
          # Gravatar::Addon::Gravatar
          expect(subject.gravatar_disabled).to eq SS.config.gravatar.disable
          expect(subject.gravatar_enabled).to eq !SS.config.gravatar.disable
          expect(subject.gravatar_image_size).to eq SS.config.gravatar.image_size
          expect(subject.gravatar_default_image_path).to eq SS.config.gravatar.default_image_path
          expect(subject.gravatar_image_view_kind).to eq page.gravatar_image_view_kind
          expect(subject.gravatar_email).to eq page.gravatar_email
          expect(subject.gravatar_screen_name).to eq page.gravatar_screen_name
        end
      end

      context "with Cms::Addon::Thumb" do
        let!(:thumb) do
          SS::File.create_empty!(
            cur_user: cms_user, site_id: cms_site.id, model: "article/page", filename: "logo.png", content_type: 'image/png'
          ) do |file|
            ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
          end
        end
        let!(:page) { create :article_page, cur_node: node, thumb: thumb }

        it do
          # Cms::Addon::Thumb
          expect(subject.thumb.name).to eq thumb.name
        end
      end

      context "with Cms::Addon::Body" do
        let(:html) { Array.new(2) { "<p>#{unique_id}</p>" }.join("\n") }
        let!(:page) { create :article_page, cur_node: node, html: html }

        it do
          # Cms::Addon::Body
          expect(subject.html).to eq html
        end
      end

      context "with Cms::Addon::Form::Page" do
        let!(:page) { create :article_page, cur_node: node }

        it do
          # Cms::Addon::Form::Page
          expect(subject.values).to be_blank
        end
      end

      context "with Event::Addon::Date" do
        let!(:term1) do
          term1_start_at = Time.zone.now.beginning_of_day
          Array.new(3) { |i| term1_start_at + i.days }
        end
        let!(:term2) do
          term2_start_at = Time.zone.now.beginning_of_day + 1.month
          Array.new(5) { |i| term2_start_at + i.days }
        end
        let!(:recurr1) do
          { kind: "date", start_at: term1.first, frequency: "daily", until_on: term1.last }
        end
        let!(:recurr2) do
          { kind: "date", start_at: term2.first, frequency: "daily", until_on: term2.last }
        end
        let!(:event_deadline) { Time.zone.now.change(min: rand(0..59)) }
        let!(:page) do
          create(
            :article_page, cur_node: node,
            event_name: unique_id, event_recurrences: [ recurr1, recurr2 ], event_deadline: event_deadline
          )
        end

        it do
          # Event::Addon::Date
          expect(subject.event_name).to eq page.event_name
          expect(subject.event_dates.length).to eq 2
          expect(subject.event_dates[0].length).to eq term1.length
          expect(subject.event_dates[0][0]).to eq term1[0]
          expect(subject.event_dates[1].length).to eq term2.length
          expect(subject.event_dates[1][0]).to eq term2[0]
          expect(subject.event_deadline).to eq page.event_deadline
        end
      end

      context "with Map::Addon::Page" do
        let!(:map_point1) { { "name" => unique_id, "loc" => [ rand(135..145), rand(30..40) ], "text" => unique_id } }
        let!(:map_point2) { { "name" => unique_id, "loc" => [ rand(135..145), rand(30..40) ], "text" => unique_id } }
        let!(:map_points) { [ map_point1, map_point2 ] }
        let!(:page) { create :article_page, cur_node: node, map_points: map_points, map_zoom_level: rand(8..12) }

        it do
          # Map::Addon::Page
          expect(subject.map_points.length).to eq 2
          # indirect access
          expect(subject.map_points[0]["name"]).to eq map_point1["name"]
          expect(subject.map_points[0]["loc"]).to eq map_point1["loc"]
          expect(subject.map_points[0]["text"]).to eq map_point1["text"]
          expect(subject.map_points[1]["name"]).to eq map_point2["name"]
          expect(subject.map_points[1]["loc"]).to eq map_point2["loc"]
          expect(subject.map_points[1]["text"]).to eq map_point2["text"]
          # [v1.16.2 or later] direct access
          expect(subject.map_points[0].name).to eq map_point1["name"]
          expect(subject.map_points[0].loc).to eq map_point1["loc"]
          expect(subject.map_points[0].text).to eq map_point1["text"]
          expect(subject.map_points[1].name).to eq map_point2["name"]
          expect(subject.map_points[1].loc).to eq map_point2["loc"]
          expect(subject.map_points[1].text).to eq map_point2["text"]

          expect(subject.map_zoom_level).not_to eq page.map_zoom_level
          expect(subject.map_zoom_level).to eq SS.config.map.googlemaps_zoom_level
          expect(subject.map_center.lat).to eq Map.center(page.cur_site).lat
          expect(subject.map_center.lng).to eq Map.center(page.cur_site).lng
        end
      end

      context "with Cms::Addon::RelatedPage" do
        let!(:related1) { create :article_page, cur_node: node, released: Time.zone.now.change(min: 1) }
        let!(:related2) { create :article_page, cur_node: node, released: Time.zone.now.change(min: 2) }
        let!(:page) { create :article_page, cur_node: node, related_page_ids: [ related1.id, related2.id ] }

        it do
          # Cms::Addon::RelatedPage
          expect(subject.related_pages.length).to eq 2
          expect(subject.related_pages[0].id).to eq related2.id
          expect(subject.related_pages[1].id).to eq related1.id
        end
      end

      context "with Contact::Addon::Page" do
        let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}" }
        let!(:page) do
          create(
            :article_page, cur_node: node, contact_state: "show", contact_charge: unique_id,
            contact_tel: "0000", contact_fax: "9999", contact_email: "#{unique_id}@example.jp",
            contact_link_url: "/#{unique_id}/", contact_link_name: unique_id,
            contact_group: group1
          )
        end

        it do
          # Contact::Addon::Page
          expect(subject.contact_state).to eq page.contact_state
          expect(subject.contact_charge).to eq page.contact_charge
          expect(subject.contact_tel).to eq page.contact_tel
          expect(subject.contact_fax).to eq page.contact_fax
          expect(subject.contact_email).to eq page.contact_email
          expect(subject.contact_link_url).to eq page.contact_link_url
          expect(subject.contact_link_name).to eq page.contact_link_name
          subject.contact_group.to_liquid.tap do |contact_group|
            expect(contact_group.to_s).to eq group1.name
            expect(contact_group.name).to eq group1.name
            expect(contact_group.full_name).to eq group1.full_name
            expect(contact_group.section_name).to eq group1.section_name
            expect(contact_group.trailing_name).to eq group1.trailing_name
            expect(contact_group.last_name).to eq group1.name.split("/").last
          end
        end
      end

      context "with Cms::Addon::Tag" do
        let!(:page) { create :article_page, cur_node: node, tags: Array.new(2) { unique_id } }

        it do
          # Cms::Addon::Tag
          expect(subject.tags.length).to eq page.tags.length
          expect(subject.tags).to eq page.tags
        end
      end

      context "with Cms::Addon::GroupPermission" do
        let!(:group1) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", order: 1 }
        let!(:group2) { create :cms_group, name: "#{cms_group.name}/#{unique_id}", order: 2 }
        let!(:page) { create :article_page, cur_node: node, group_ids: [ group1.id, group2.id ] }

        it do
          # Cms::Addon::GroupPermission
          expect(subject.groups.length).to eq 2
          expect(subject.groups[0].name).to eq group1.name
          expect(subject.groups[1].name).to eq group2.name
        end
      end
    end

    context "with form" do
      let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
      let!(:column1) { create(:cms_column_text_field, cur_form: form, order: 1, input_type: 'text') }
      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(column: column1, value: unique_id * 2)
          ]
        )
      end
      let(:html) { "<p>{{ values['#{column1.name}'] }}</p>" }

      before do
        node.st_form_ids = [ form.id ]
        node.save!

        form.html = html
        form.save!
      end

      context "with Cms::Addon::Body" do
        it do
          # Cms::Addon::Body
          expect(subject.html).to eq "<p>#{page.column_values[0].value}</p>"
        end

        context "with column_name_type is unrestricted" do
          let(:name) { "name/#{unique_id}" }
          let!(:column1) do
            create(:cms_column_text_field, cur_form: form, name: name, order: 1, input_type: 'text')
          end
          let(:html) { "<p>{{ values['#{name.sub('/', '_')}'] }}</p>" }

          around do |example|
            save_config = SS.config.replace_value_at(:cms, 'column_name_type', 'unrestricted')
            example.run
            SS.config.replace_value_at(:cms, 'column_name_type', save_config)
          end

          it do
            expect(subject.html).to eq "<p>#{page.column_values[0].value}</p>"
          end
        end
      end

      context "with Cms::Addon::Form::Page" do
        it do
          # Cms::Addon::Form::Page
          expect(subject.values.length).to eq 1
          expect(subject.values[0].value).to eq page.column_values[0].value
        end
      end
    end
  end
end
