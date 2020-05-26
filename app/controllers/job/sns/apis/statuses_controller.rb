class Job::Sns::Apis::StatusesController < ApplicationController
  include ::Sns::BaseFilter
  include SS::CrudFilter
  include SS::AjaxFilter

  model Job::Log

  private

  def set_item
    @item ||= begin
      id_or_job_id = params[:id].to_s

      item = @model.where(id: id_or_job_id, user_id: @cur_user.id).first
      item ||= @model.where(job_id: id_or_job_id, user_id: @cur_user.id).first
      item ||= Job::Task.where(name: id_or_job_id, user_id: @cur_user.id).first
      raise Mongoid::Errors::DocumentNotFound.new(@model, id: id_or_job_id) if item.blank?

      item.attributes = fix_params
      item
    end
  end

  public

  def show
    render
  end
end
