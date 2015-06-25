class Ezine::Agents::Nodes::FormController < ApplicationController
  include Cms::NodeFilter::View

  before_action :set_entry, only: [:add, :update, :delete, :confirm]
  before_action :set_columns, only: [:add, :update, :confirm]

  helper "ezine/form"

  private
    def set_entry
      @entry = Ezine::Entry.new(site_id: @cur_site.id, node_id: @cur_node.id)
      @entry.in_data = params[:item][:in_data] rescue {}
    end

    def set_columns
      @columns = Ezine::Column.site(@cur_site).node(@cur_node).
        where(state: "public").order_by(order: 1)
    end

    def get_params
      fix_fields = permit_fields + [ in_data: @columns.map{ |c| c.id.to_s } ]
      params.require(:item).permit(fix_fields).merge(fix_params)
    end

  public
    def confirm
      raise "403" unless params[:submit].present?

      @entry.email = params[:item][:email]
      @entry.email_type = params[:item][:email_type]
      @entry.email_type = 'html' if @entry.email_type.nil?
      entry_type = request[:item][:entry_type]
      @entry.entry_type = entry_type
      @entry.in_data = nil if @entry.entry_type == "delete"

      if @entry.save
        @entry_type_string = t("ezine.entry_type.#{entry_type}")
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
