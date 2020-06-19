class Guide::Agents::Nodes::GuideController < ApplicationController
  include Cms::NodeFilter::View
  helper Guide::ListHelper

  before_action :set_answers

  private

  def set_answers
    @answers = params[:condition].to_s
    @answers = @answers.split("-").map { |transitions| transitions.split(",") }

    if params[:question].present?
      question = ::Guide::Question.find(params[:question])
      question_type = question.question_type

      if params[:answers].present?
        if question_type == "choices"
          params[:answers].each do |no, transitions|
            @answers[no.to_i] = transitions
          end
        elsif question_type == "yes_no"
          params[:answers].each do |no, transitions|
            if params[:submit] == I18n.t("guide.links.applicable")
              transitions = [transitions[0]]
            elsif params[:submit] == I18n.t("guide.links.not_applicable")
              transitions = [transitions[1]]
            else
              transitions = []
            end
            @answers[no.to_i] = transitions
          end
        else
          params[:answers].each do |no, transitions|
            @answers[no.to_i] = []
          end
        end
      end
    end

    condition = @answers.map { |transitios| transitios.join(",") }
    @condition = condition.join("-")

    condition.pop
    @before_condition = condition.join("-")

    @no = @answers.size
  end

  public

  def index
    @diagram = ::Guide::QuestionDiagram.new @cur_node
    @diagram.input_answers(@answers)
  end

  def dialog
    @diagram = ::Guide::QuestionDiagram.new @cur_node
    @question = @diagram.input_answers(@answers).first

    @longest_length = @diagram.longest_length
    @evaluated_length = @diagram.evaluated_length

    if @question.nil?
      redirect_to "#{@cur_node.url}result/#{@condition}"
      return
    else
      render :dialog
    end
  end

  def result
    @cur_node.name = "【結果】#{@cur_node.name}"

    @diagram = ::Guide::QuestionDiagram.new @cur_node
    @diagram.input_answers(@answers)
    @procedures = @diagram.procedures
    @other_procedures = @cur_node.procedures
  end

  def answer
    @cur_node.name = "【結果】#{@cur_node.name}"

    @diagram = ::Guide::QuestionDiagram.new @cur_node
    @diagram.input_answers(@answers)
    @procedures = @diagram.procedures
  end

  def procedure
    @cur_node.name = "【結果】#{@cur_node.name}"

    @diagram = ::Guide::QuestionDiagram.new @cur_node
    @procedures = @diagram.all_procedures
  end
end
