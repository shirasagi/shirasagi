class Ezine::Agents::Nodes::FormController < ApplicationController
  include Cms::NodeFilter::View

  before_action :set_entries, only: [:new, :update, :remove, :confirm]

  private
    def set_entries
      @entry = Ezine::Entry.new(site_id: @cur_site.id, node_id: @cur_node.id)
    end

    def get_entry_type(type)
      case type
      when "new"
        "add"
      when "update"
        "update"
      when "remove"
        "delete"
      end
    end

  public
    def confirm
      entry_type = get_entry_type request.env["HTTP_REFERER"].split("/").last

      raise "403" unless params[:submit].present?

      @entry.email = params[:item][:email]
      @entry.email_type = params[:item][:email_type]
      @entry.email_type = 'html' if @entry.email_type.nil?
      @entry.entry_type = entry_type

      if @entry.save
        case entry_type
        when "add"
          @entry_type_string = t("ezine.entry_type.add")
        when "update"
          @entry_type_string = t("ezine.entry_type.update")
        when "delete"
          @entry_type_string = t("ezine.entry_type.delete")
        end

        render action: :confirm
      else
        case entry_type
        when "add"
          render action: :new
        when "update"
          render action: :update
        when "delete"
          render action: :remove
        end
      end
    end

    def verify
      entry = Ezine::Entry.where(verification_token: params[:token]).first
      if entry.present?
        entry.verify
      else
        raise "403"
      end
    end
end
