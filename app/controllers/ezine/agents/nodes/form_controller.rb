class Ezine::Agents::Nodes::FormController < ApplicationController
  include Cms::NodeFilter::View

  before_action :set_entry, only: [:add, :update, :delete, :confirm]

  private
    def set_entry
      @entry = Ezine::Entry.new(site_id: @cur_site.id, node_id: @cur_node.id)
    end

    def entry_type
      File.basename request.env["HTTP_REFERER"], ".*"
    end

  public
    def confirm
      raise "403" unless params[:submit].present?

      @entry.email = params[:item][:email]
      @entry.email_type = params[:item][:email_type]
      @entry.email_type = 'html' if @entry.email_type.nil?
      @entry.entry_type = entry_type

      if @entry.save
        @entry_type_string = t("ezine.entry_type." + entry_type)
        render action: :confirm
      else
        render action: entry_type.to_sym
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
