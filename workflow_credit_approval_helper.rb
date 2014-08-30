# -*- encoding: utf-8 -*-
class WorkflowCreditApprovalHelper < WorkflowHelper
  def save_examiner
    #WorkflowLog.create!(:message => "save_examiner")
    @workitem.fields['blade']['default_examiner_id'] = @req.params['examiner_id']
    @workitem.fields['blade']['receiver_id'] = @req.params['examiner_id']
  end

  def remind_risk_dept_head
    #WorkflowLog.create!(:message => "remind_risk_dept_head")
  end

  def save_examiner_suggest
    suggest = @req.params['suggest']
    trans = {
      'aggree' => '同意',
      'deny' => '否决',
      'aggree_with_condition' => '有条件同意',
      'suspend' => '暂缓'
    }
    comments = "#{trans[suggest]}: #{@req.params[suggest]}"
    @req.instance_variable_set('@comments', comments)
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
      "#{Role.where(:code => @workitem.participant_name).first.name}设置终审人为:#{Role.where(:code => @req.params['final_decision_maker_role']).first.name}" 
    end

    @workitem.fields['blade']['final_decision_maker_role'] = @req.params['final_decision_maker_role']
    case @workitem.fields['blade']['final_decision_maker_role']
    when 'committee_director'
      @workitem.fields['blade']['VOTE.review'] = {
        :custom_fields => [
          { :type => 'radio', :name => 'final_decision', :value => 'yes', :label => '否决' },
          { :type => 'radio', :name => 'final_decision', :value => 'no', :label => '同意' },
      ]}
    when 'president'
      @workitem.fields['blade'].delete('VOTE.review')
    end
  end
end

