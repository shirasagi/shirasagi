class Contact::ContactsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model SS::Contact

  navi_view "cms/main/group_navi"
  skip_before_action :set_item

  ContactGroupPair = Struct.new(:contact, :group, keyword_init: true) do
    def id
      contact.try(:id)
    end
  end

  private

  def set_crumbs
    @crumbs << [ t("modules.contact"), url_for(action: :index) ]
  end

  public

  def index
    raise "403" unless Cms::Group.allowed?(:read, @cur_user, site: @cur_site)

    limit = 50
    offset = params[:page].numeric? ? (params[:page].to_i - 1) * limit : 0

    stages = [{ "$match" => { contact_groups: { "$exists" => true } } }]
    if params[:s].present?
      Cms::Group.unscoped do
        criteria = Cms::Group.search(params[:s])
        stages << { "$match" => criteria.selector }
      end
    end
    stages << { "$sort" => { order: 1, name: 1 } }
    stages << { "$unwind" => "$contact_groups" }
    stages << {
      "$facet" => {
        "paginatedResults" => [{ "$skip" => offset }, { "$limit" => limit }],
        "totalCount" => [{ "$count" => "count" }]
      }
    }

    results = Cms::Group.collection.aggregate(stages)

    @items = results.first["paginatedResults"].map do |result_doc|
      contact = ::Mongoid::Factory.from_db(SS::Contact, result_doc["contact_groups"])
      group = ::Mongoid::Factory.from_db(Cms::Group, result_doc.except("contact_groups"))
      ContactGroupPair.new(contact: contact, group: group)
    end
    total_count = results.first["totalCount"].first["count"]
    @items = Kaminari.paginate_array(@items, limit: limit, offset: offset, total_count: total_count)
  end

  def destroy
    group_id, contact_id = params[:id].to_s.split(":")
    if !group_id.numeric? || !BSON::ObjectId.legal?(contact_id)
      render json: { title: "Not Found" }, status: :not_found
      return
    end

    group_item = Cms::Group.site(@cur_site).find(group_id) rescue nil
    if !group_item
      render json: { title: "Not Found" }, status: :not_found
      return
    end

    contact_item = group_item.contact_groups.where(id: contact_id).first
    if !contact_item
      render json: { title: "Not Found" }, status: :not_found
      return
    end

    pages = Cms::Page.all.where(contact_group_id: group_item.id, contact_group_contact_id: contact_item.id)
    if pages.present?
      render json: { title: t("mongoid.errors.models.ss/contact.in_use") }, status: :bad_request
      return
    end

    contact_item.destroy
    render json: { title: I18n.t("ss.notice.deleted") }, status: :ok
  end
end
