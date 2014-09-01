# -*- encoding: utf-8 -*-
class WorkflowCreditApprovalHelper < WorkflowHelper
  def save_examiner
    @workitem.fields['blade']['default_examiner_id'] = @req.params['examiner_id']
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
      "#{Role.where(:code => @workitem.participant_name).first.name}选择终审人为:#{Role.where(:code => @req.params['final_decision_maker_role']).first.name}" 
    end

    @workitem.fields['blade']['final_decision_maker_role'] = @req.params['final_decision_maker_role']
  end

  def custom_fields_for_committee_director
    if @workitem.fields['blade']['final_decision_maker_role'] == 'committee_director'
      @new_custom_fields = { '否决' => { :type => 'checkbox', :name => 'declined' },
        '同意' =>  { :type => 'checkbox', :name => 'agreed'} }
    end
  end

  def custom_fields_for_business_manager
    if @workitem.fields['more_info_from_committee_secretary']
      @new_custom_fields = { '发送给评审委员会委员' => { :type => 'checkbox', :name => 'back_to_committee_secretary' } }
    end
  end
end

