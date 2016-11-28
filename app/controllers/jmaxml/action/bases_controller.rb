class Jmaxml::Action::BasesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::Action::Base
  navi_view "rss/main/navi"

  private
    def fix_params
      { cur_site: @cur_site }
    end

  public
    def show
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Jmaxml::Action::PublishPage'
        redirect_to jmaxml_action_publish_page_path
      when 'Jmaxml::Action::SwitchUrgency'
        redirect_to jmaxml_action_switch_urgency_path
      when 'Jmaxml::Action::SendMail'
        redirect_to jmaxml_action_send_mail_path
      else
        raise "400"
      end
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render file: :choice
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.in_type
      when 'Jmaxml::Action::PublishPage'
        redirect_to new_jmaxml_action_publish_page_path
      when 'Jmaxml::Action::SwitchUrgency'
        redirect_to new_jmaxml_action_switch_urgency_path
      when 'Jmaxml::Action::SendMail'
        redirect_to new_jmaxml_action_send_mail_path
      else
        raise "400"
      end
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Jmaxml::Action::PublishPage'
        redirect_to edit_jmaxml_action_publish_page_path
      when 'Jmaxml::Action::SwitchUrgency'
        redirect_to edit_jmaxml_action_switch_urgency_path
      when 'Jmaxml::Action::SendMail'
        redirect_to edit_jmaxml_action_send_mail_path
      else
        raise "400"
      end
    end

    def delete
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)

      case @item.class.name
      when 'Jmaxml::Action::PublishPage'
        redirect_to delete_jmaxml_action_publish_page_path
      when 'Jmaxml::Action::SwitchUrgency'
        redirect_to delete_jmaxml_action_switch_urgency_path
      when 'Jmaxml::Action::SendMail'
        redirect_to delete_jmaxml_action_send_mail_path
      else
        raise "400"
      end
    end
end
