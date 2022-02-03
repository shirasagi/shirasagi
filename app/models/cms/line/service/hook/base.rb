module Cms::Line::Service::Hook
  class Base
    include SS::Document
    include SS::Reference::Site
    include SS::Reference::User
    include Cms::SitePermission

    store_in collection: "cms_line_service_hooks"

    set_permission_name "cms_line_services", :use

    field :name, type: String
    field :order, type: Integer, default: 0
    field :action_type, type: String
    field :action_data, type: String

    permit_params :name, :order
    permit_params :action_type, :action_data

    belongs_to :group, class_name: "Cms::Line::Service::Group", inverse_of: :hooks

    validates :name, presence: true, length: { maximum: 40 }
    validates :action_type, presence: true
    validates :action_data, presence: true
    validates :group_id, presence: true

    default_scope ->{ order_by(order: 1) }

    def type
    end

    def type_options
      self.class.type_options
    end

    def action_type_options
      %w(message postback).map { |k| [I18n.t("cms.options.line_action_type.#{k}"), k] }
    end

    def processor(site, node, client, request)
      klass = self.class.to_s.sub("Cms::Line::Service::Hook::", "Cms::Line::Service::Processor::").constantize
      item = klass.new(
        service: self,
        site: site,
        node: node,
        client: client,
        request: request)
      item.parse_request
      item
    end

    def delegate_processor(delegator, event)
      klass = self.class.to_s.sub("Cms::Line::Service::Hook::", "Cms::Line::Service::Processor::").constantize
      item = klass.new(
        service: self,
        site: delegator.site,
        node: delegator.node,
        client: delegator.client,
        request: delegator.request
      )
      item.signature = delegator.signature
      item.body = delegator.body
      item.events = [event]
      item.event_session = delegator.event_session
      item
    end

    # HUB
    def switch_hook(processor, event)
      return false if event["type"] != action_type

      case action_type
      when "message"
        return false if event["message"]["text"] != action_data
      when "postback"
        return false if event["postback"]["data"] != action_data
      else
        return false
      end

      processor.event_session.hook = self
      processor.event_session.update

      delegate_processor(processor, event).start
      return true
    end

    def delegate(processor, event)
      return false if processor.event_session.hook_id != id
      delegate_processor(processor, event).call
      true
    end

    private

    class << self
      def type_options
        hooks = [
          Cms::Line::Service::Hook::FacilitySearch,
          Cms::Line::Service::Hook::Chat,
          Cms::Line::Service::Hook::GdChat,
          Cms::Line::Service::Hook::MyPlan,
          Cms::Line::Service::Hook::ImageMap,
          Cms::Line::Service::Hook::JsonTemplate,
        ].map { |klass| klass.new.type }
        hooks.map { |k| [I18n.t("cms.options.line_service_type.#{k}"), k] }
      end

      def search(params)
        criteria = all
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name
        end
        criteria
      end
    end
  end
end
