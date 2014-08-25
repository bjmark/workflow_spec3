#encoding:utf-8

class WorkflowCreditHelper < WorkflowHelper
  def save_examiner
    @workitem.fields['blade']['default_examiner_id'] = @req.params['examiner_id']
    @workitem.fields['blade']['receiver_id'] = @req.params['examiner_id']
  end

  def remind_risk_dept_head
  end

  def save_examiner_suggest
    @req.instance_variable_set('@comments', 'abc')
  end

  def set_receiver
    @workitem.fields['blade']['receiver_id'] = 
      @workitem.fields['blade']['default_examiner_id']
  end
  
  def validate_examiner
    error = []
    if @req.params['examiner_id'] == ''
      error << '请指定审查人'
    end
    error
  end

  def validate_suggest
    error = []
    if @req.params['suggest'].nil?
      error << '请输入审查建议'
    end
    error
  end

  def save_final_decision_maker
    if @workitem.fields['blade']['final_decision_maker_role'] != @req.params['final_decision_maker_role']
      @workitem.fields['blade']['final_decision_maker_role_history'] = [] unless @workitem.fields['blade']['final_decision_maker_role_history']
      @workitem.fields['blade']['final_decision_maker_role_history'] <<
      case @workitem.participant_name
      when 'risk_dept_examiner'
        "1"
      when 'risk_dept_reviewer'
        "2"
      when 'risk_dept_head'
        "3"
      end
    end
    @workitem.fields['blade']['final_decision_maker_role'] = @req.params['final_decision_maker_role']
    case @workitem.fields['blade']['final_decision_maker_role']
    when 'committee_director'
      @workitem.fields['blade']['committee_director1'] = { "下一步:总裁审批" => 'del' }
    when 'president'
      @workitem.fields['blade']['committee_director1'] = { 
        "同意" => 'del',
        "否决" => 'del'
      }
    end
  end
end

