class Contact::Apis::ContactsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Group

  class Aggregator
    include ActiveModel::Model

    attr_accessor :cur_site, :cur_user, :s, :page, :limit

    STAGES = %i[
      stage_default_selector stage_site_selector stage_normalize_contact_groups_and_unwind
      stage_search_selector stage_sort stage_paginate].freeze

    FIELDS_TO_SEARCH = %w(
      name
      ncontact_groups.contact_group_name ncontact_groups.contact_tel ncontact_groups.contact_falx
      ncontact_groups.contact_email ncontact_groups.contact_link_url ncontact_groups.contact_link_name
    ).freeze

    def call
      @stages = []
      STAGES.each do |handler|
        send(handler)
      end

      aggregation_view = Cms::Group.collection.aggregate(@stages)
      result_doc = aggregation_view.first

      items = result_doc["paginatedResults"].map do |result|
        [
          Mongoid::Factory.from_db(Cms::Group, result.except("ncontact_groups")),
          Mongoid::Factory.from_db(SS::Contact, result["ncontact_groups"])
        ]
      end
      if result_doc["totalCount"].present? && result_doc["totalCount"][0].present?
        total_count = result_doc["totalCount"][0]["count"]
      end
      total_count ||= 0

      Kaminari.paginate_array(items, limit: limit, offset: offset, total_count: total_count)
    end

    private

    def offset
      @offset ||= page * limit
    end

    def stage_default_selector
      default_selector = Cms::Group.all.selector
      if default_selector.present?
        @stages << { "$match" => default_selector }
      end
    end

    def stage_site_selector
      site_selector = Cms::Group.unscoped.site(@cur_site).selector
      if site_selector.present?
        @stages << { "$match" => site_selector }
      end
    end

    def stage_normalize_contact_groups_and_unwind
      # flatten contact_groups
      @stages << {
        "$addFields" => {
          ncontact_groups: {
            "$cond" => [
              # boolean-expression
              { "$isArray" => "$contact_groups" },
              # true-case
              "$contact_groups",
              # false-case
              [{}]
            ]
          }
        }
      }
      @stages << { "$project" => { contact_groups: 0 } }
      @stages << { "$unwind" => "$ncontact_groups" }
    end

    def stage_search_selector
      return if s.blank?

      keyword = s[:keyword].to_s
      return if keyword.blank?

      words = keyword.split(/[\s　]+/).uniq.compact.map { |w| /#{::Regexp.escape(w)}/i }
      words = words[0..4]
      conditions = words.map do |word|
        { "$or" => FIELDS_TO_SEARCH.map { |field| { field => word } } }
      end

      conditions.each do |condition|
        @stages << { "$match" => condition }
      end
    end

    def stage_sort
      @stages << { "$sort" => { order: 1, name: 1, _id: 1, "ncontact_groups._id" => 1 } }
    end

    def stage_paginate
      @stages << {
        "$facet" => {
          "paginatedResults" => [{ "$skip" => offset }, { "$limit" => limit }],
          "totalCount" => [{ "$count" => "count" }]
        }
      }
    end
  end

  def index
    @single = params[:single].present?
    @multi = !@single

    if params.key?(:page) && params[:page].numeric?
      page = params[:page].to_i
    else
      page = 0
    end
    aggregator = Aggregator.new(cur_site: @cur_site, cur_user: @cur_user, s: params[:s], page: page, limit: 50)
    @items = aggregator.call
  end
end
