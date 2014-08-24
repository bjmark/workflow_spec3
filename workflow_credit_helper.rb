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

  def set_view2
    @workitem.fields['blade']['view'] = 'view13_2'
  end
  
  def set_view3
    @workitem.fields['blade']['view'] = 'view13_3'
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
end

