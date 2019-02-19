module Opendata::Addon::CounterHtml
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    field :html, type: String, default: ""
    permit_params :html
  end

  def datasets
    @datasets ||= begin
      Opendata::Dataset.site(site).and_public
    end
  end

  def dataset_tags
    @dataset_tags ||= datasets.aggregate_array(:tags)
  end

  def dataset_groups
    @dataset_groups ||= Opendata::DatasetGroup.site(site).and_public
  end

  def estat_datasets
    @estat_datasets ||= begin
      estat_category_ids = Opendata::Node::EstatCategory.site(site).and_public.pluck(:id)
      datasets.in(estat_category_ids: estat_category_ids)
    end
  end

  def estat_dataset_tags
    @estat_dataset_tags ||= begin
      estat_datasets.aggregate_array(:tags)
    end
  end

  def estat_dataset_groups
    @estat_dataset_groups ||= begin
      dataset_groups.in(id: estat_datasets.pluck(:dataset_group_ids).flatten.uniq)
    end
  end

  def apps
    @apps ||= begin
      Opendata::App.site(site).and_public
    end
  end

  def app_tags
    @app_tags ||= apps.aggregate_array(:tags)
  end

  def ideas
    @ideas ||= begin
      Opendata::Idea.site(site).and_public
    end
  end

  def idea_tags
    @idea_tags ||= ideas.aggregate_array(:tags)
  end

  def counter_html
    html = self.html.presence || I18n.t("opendata.counter_html").join

    # datasets

    if html.index('#{dataset_count}')
      html = html.gsub('#{dataset_count}', datasets.count.to_s)
    end

    if html.index('#{dataset_tag_count}')
      html = html.gsub('#{dataset_tag_count}', dataset_tags.count.to_s)
    end

    if html.index('#{dataset_group_count}')
      html = html.gsub('#{dataset_group_count}', dataset_groups.count.to_s)
    end

    # estat datasets

    if html.index('#{estat_dataset_count}')
      html = html.gsub('#{estat_dataset_count}', estat_datasets.count.to_s)
    end

    if html.index('#{estat_dataset_tag_count}')
      html = html.gsub('#{estat_dataset_tag_count}', estat_dataset_tags.count.to_s)
    end

    if html.index('#{estat_dataset_group_count}')
      html = html.gsub('#{estat_dataset_group_count}', estat_dataset_groups.count.to_s)
    end

    # apps

    if html.index('#{app_count}')
      html = html.gsub('#{app_count}', apps.count.to_s)
    end

    if html.index('#{app_tag_count}')
      html = html.gsub('#{app_tag_count}', app_tags.count.to_s)
    end

    # ideas

    if html.index('#{idea_count}')
      html = html.gsub('#{idea_count}', ideas.count.to_s)
    end

    if html.index('#{idea_tag_count}')
      html = html.gsub('#{idea_tag_count}', idea_tags.count.to_s)
    end

    html
  end
end
