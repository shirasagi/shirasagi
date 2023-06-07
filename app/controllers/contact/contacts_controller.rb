class Contact::ContactsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model SS::Contact

  navi_view "cms/main/group_navi"

  ContactGroupPair = Struct.new(:contact, :group, keyword_init: true) do
    def id
      contact.try(:id)
    end
  end

  def set_crumbs
    @crumbs << [ t("modules.contact"), url_for(action: :index) ]
  end

  def index
    raise "403" unless Cms::Group.allowed?(:read, @cur_user, site: @cur_site)

    limit = 50
    offset = params[:page].numeric? ? (params[:page].to_i - 1) * limit : 0

    stages = [
      { "$match" => { contact_groups: { "$exists" => true } } },
      { "$sort" => { order: 1, name: 1 } },
      { "$unwind" => "$contact_groups" },
      {
        "$facet" => {
          "paginatedResults" => [{ "$skip" => offset }, { "$limit" => limit }],
          "totalCount" => [{ "$count" => "count" }]
        }
      }
    ]

    results = Cms::Group.collection.aggregate(stages)

    @items = results.first["paginatedResults"].map do |result_doc|
      contact = ::Mongoid::Factory.from_db(SS::Contact, result_doc["contact_groups"])
      group = ::Mongoid::Factory.from_db(Cms::Group, result_doc.except("contact_groups"))
      ContactGroupPair.new(contact: contact, group: group)
    end
    total_count = results.first["totalCount"].first["count"]
    @items = Kaminari.paginate_array(@items, limit: limit, offset: offset, total_count: total_count)
  end
end
