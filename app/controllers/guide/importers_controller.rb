class Guide::ImportersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/node/main/navi"

  model Guide::Importer

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    @item = Guide::Importer.new fix_params
  end

  def download_procedures
    @item = Guide::Importer.new fix_params
    filename = "procedures_#{Time.zone.now.to_i}.csv"
    encoding = "Shift_JIS"
    send_enum(@item.procedures_enum, type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def import_procedures
    @item = Guide::Importer.new fix_params

    if request.get? || request.head?
      render :import
      return
    end

    @item.attributes = get_params
    render_update @item.import_procedures, location: { action: :index }, render: { template: "import" }
  end

  def download_questions
    @item = Guide::Importer.new fix_params
    filename = "questions_#{Time.zone.now.to_i}.csv"
    encoding = "Shift_JIS"
    send_enum(@item.questions_enum, type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def import_questions
    @item = Guide::Importer.new fix_params

    if request.get? || request.head?
      render :import
      return
    end

    @item.attributes = get_params
    render_update @item.import_questions, location: { action: :index }, render: { template: "import" }
  end

  def download_transitions
    @item = Guide::Importer.new fix_params
    filename = "transitions_#{Time.zone.now.to_i}.csv"
    encoding = "Shift_JIS"
    send_enum(@item.transitions_enum, type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def import_transitions
    @item = Guide::Importer.new fix_params

    if request.get? || request.head?
      render :import
      return
    end

    @item.attributes = get_params
    render_update @item.import_transitions, location: { action: :index }, render: { template: "import" }
  end

  def download_combinations
    @item = Guide::Importer.new fix_params
    filename = "guide#{@cur_node.id}_#{Time.zone.now.to_i}.csv"
    encoding = "Shift_JIS"
    send_enum(@item.combinations_enum, type: "text/csv; charset=#{encoding}", filename: filename)
  end

  def import_combinations
    @item = Guide::Importer.new fix_params

    if request.get? || request.head?
      render :import
      return
    end

    @item.attributes = get_params
    render_update @item.import_combinations, location: { action: :index }, render: { template: "import" }
  end

  def download_template
    path = ::File.join(Rails.root, "spec/fixtures/guide/guide_templates.zip")
    send_file path, disposition: :attachment, x_sendfile: true
  end
end
