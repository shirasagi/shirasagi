#frozen_string_literal: true

class Gws::Tabular::File::ActQuery < ApplicationQuery
  attr_accessor :cur_site, :cur_user, :cur_form, :act

  validates :act, inclusion: { in: %w(all approver applicant), allow_blank: true }

  WORKFLOW_STATE_FOR_READABLE_APPROVERS = %w(request approve approve_without_approval remand).freeze
  WORKFLOW_STATE_FOR_READABLE_CIRCULARS = %w(approve approve_without_approval).freeze

  def query
    return base_criteria if act.blank?
    # ワークフローが無効の場合、state による検索は機能しない
    return base_criteria unless cur_form.workflow_enabled?

    # サブクエリ構築時に `unscoped` を用いているが、`unscoped` を呼び出すと現在の検索条件が消失してしまう。
    # それを防ぐため、前もって現在の検索条件を複製しておく。
    criteria = self.base_criteria.dup

    case act
    when 'approver'
      # 承認依頼されているもの（実体は承認者のためのビュー）
      criteria.where(workflow_approvers: { '$elemMatch' => { user_id: cur_user.id } })
    when 'applicant'
      # 承認依頼したもの（実体は申請者のためのビュー）
      criteria.where('$and' => [{ '$or' => [{ workflow_user_id: cur_user.id }, { workflow_agent_id: cur_user.id }] }])
    else # 'all'
      # すべて
      cur_user_group_ids = cur_user.groups.site(cur_site).pluck(:id)
      readable_conditions = build_readable_conditions(
        cur_site: cur_site, cur_user: cur_user, cur_user_group_ids: cur_user_group_ids, cur_form: cur_form)
      criteria.where('$and' => [{ '$or' => readable_conditions }])
    end
  end

  private

  def build_readable_conditions(cur_site:, cur_user:, cur_user_group_ids:, cur_form:)
    ret = []
    if cur_form.try(:owned?, cur_user)
      # 定義の所有者の場合、その定義の管理者なので全部閲覧可能とする
      allow_selector = model.unscoped do
        model.all.allow(:read, cur_user, site: cur_site).selector
      end
      ret << allow_selector
    else
      public_selector = model.unscoped do
        model.all.and_public.selector
      end
      ret << public_selector
    end
    ret << { user_id: cur_user.id }
    ret << { workflow_user_id: cur_user.id }
    ret << { workflow_agent_id: cur_user.id }
    ret << {
      workflow_state: { '$in' => WORKFLOW_STATE_FOR_READABLE_APPROVERS },
      workflow_approvers: {
        '$elemMatch' => { user_id: cur_user.id }
      }
    }
    ret << {
      workflow_state: { '$in' => WORKFLOW_STATE_FOR_READABLE_CIRCULARS },
      workflow_circulations: {
        '$elemMatch' => { user_id: cur_user.id }
      }
    }
    ret << {
      workflow_state: { '$in' => WORKFLOW_STATE_FOR_READABLE_CIRCULARS },
      destination_user_ids: cur_user.id
    }
    ret << {
      workflow_state: { '$in' => WORKFLOW_STATE_FOR_READABLE_CIRCULARS },
      destination_group_ids: { "$in" => cur_user_group_ids }
    }
    ret
  end
end
