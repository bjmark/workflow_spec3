#encoding:utf-8

class WorkflowCreditHelper < WorkflowHelper
  def save_examiner
    @workitem.fields['blade']['default_examiner_id'] = @req_params['examiner_id']
    @workitem.fields['blade']['receiver_id'] = @req_params['examiner_id']
  end

  def remind_risk_dept_head
  end

  def save_examiner_suggest
  end
end

