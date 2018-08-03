module Workflow::WizardFilter
  extend ActiveSupport::Concern

  private

  def validate_domain(user_id)
    email = SS::User.find(user_id).email
    @cur_site.email_domain_allowed?(email)
  end

  public

  def do_reroute
    level = Integer(params[:level])
    user_id = Integer(params[:user_id])
    new_user_id = Integer(params[:new_user_id])

    workflow_approvers = @item.workflow_approvers.to_a.dup
    workflow_approver = workflow_approvers.find do |workflow_approver|
      workflow_approver[:level] == level && workflow_approver[:user_id] == user_id
    end

    if !workflow_approver
      render json: [ I18n.t('errors.messages.no_approvers') ], status: :bad_request
      return
    end

    workflow_approver[:user_id] = new_user_id
    if workflow_approver[:state] != 'request' && workflow_approver[:state] != 'pending'
      workflow_approver[:state] = 'request'
    end
    workflow_approver[:comment] = ''

    @item.workflow_approvers = workflow_approvers
    @item.save!

    if workflow_approver[:state] == 'request' && validate_domain(new_user_id)
      args = {
        f_uid: @item.workflow_user_id, t_uid: new_user_id, site: @cur_site, page: @item,
        url: params[:url], comment: @item.workflow_comment
      }

      Workflow::Mailer.request_mail(args).deliver_now
    end

    render json: { id: @item.id }, status: :ok
  rescue Mongoid::Errors::Validations
    render json: @item.errors.full_messages, status: :bad_request
  rescue => e
    render json: [ e.message ], status: :bad_request
  end

  def circulation
    if request.get?
      @redirect_to = params[:redirect_to] || request.referer
      render file: 'circulation', layout: "ss/ajax"
      return
    end

    @item.update_workflow_circulation_state(@cur_user, "seen", params[:comment].to_s)
    @item.save

    redirect_to params[:redirect_to], notice: I18n.t("workflow.notice.set_seen")
  end
end
