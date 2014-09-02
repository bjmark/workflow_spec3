#encoding:utf-8

Ruote.process_definition :code => 'credit_approval', :name => "授信审批",
  :version => "1.0.0", :target_model => 'Proposal' do
  cursor do
    set :field => 'blade', :value => {}
    set :field => 'blade.helper', :value => 'WorkflowCreditApprovalHelper' 

    business_manager :tag => 'INIT.handler', :name => '主办或协办立项申请'
    business_dept_head :tag => 'INIT.head_review', :name => '业务负责人审批',
      :custom_fields => { '否决' => { :type => 'checkbox', :name => 'declined'} }
    
    jump :to => 'finish', :if => "${f:declined} == yes"

    risk_dept_reviewer :tag => 'INIT.risk_dispatch', :name => '项目复审岗派发',
      :in_form => 'in_form_credit_approval_1',
      :before_proceed => { :proceed => 'save_examiner, remind_risk_dept_head'
    }
    #use '-' to replace '.', as blade.INIT.risk_dispatch_user_id will lead to field['blade.INIT.risk_dispatch_user_id']
    set :field => 'blade.INIT-risk_exam_user_id', :value => '${f:blade.default_examiner_id}'

    risk_dept_examiner :tag => 'INIT.risk_exam', :name => '立项审查',
      :custom_fields => { '修改或补充材料' => { :type => 'checkbox', :name => 'more_info'} },
      :form => 'form_credit_approval_2',
      :before_proceed => { :proceed => 'save_examiner_suggest if !more_info'
    }

    jump :to => 'INIT.handler', :if => '${f:more_info} == yes'

    risk_dept_reviewer :tag => 'INIT.risk_review', :name => '项目复核岗复核'

    risk_dept_head :tag => 'INIT.risk_head_review', :name => '风险负责人审批',
      :custom_fields => { '否决' => { :type => 'checkbox', :name => 'declined'} }

    jump :to => 'finish', :if => "${f:declined} == yes"

    business_manager :tag => 'DD.handler', :name => '尽职调查',
      :before_edit => 'custom_fields_for_business_manager'

    jump :to => 'VOTE.collect_votes', :if => "${f:back_to_committee_secretary} == yes"

    business_dept_head :tag => 'DD.head_review', :name => '业务部负责人审批'

    risk_dept_reviewer :tag => 'DD.risk_dispatch', :name => '项目复审岗派发',
      :in_form => 'in_form_credit_approval_1',
      :before_proceed => { :proceed => 'save_examiner, remind_risk_dept_head'
    }
    set :field => 'blade.DD-risk_examine_user_id', :value => '${f:blade.default_examiner_id}'

    risk_dept_examiner :tag => 'DD.risk_examine', :name => '项目审查',
      :custom_fields => { '修改或补充材料' => { :type => 'checkbox', :name => 'more_info'} },
      :in_form => 'in_form_credit_approval_3',
      :before_proceed => { :proceed => 'save_final_decision_maker'
    }
    
    jump :to => 'DD.handler', :if => '${f:more_info} == yes'

    risk_dept_reviewer :tag => 'DD.risk_review', :name => '项目复核岗复审',
      :in_form => 'in_form_credit_approval_3',
      :before_proceed => { :proceed => 'save_final_decision_maker'
    }

    risk_dept_head :tag => 'VOTE.risk_head', :name => '负责人审批',
      :in_form => 'in_form_credit_approval_3',
      :custom_fields => { '否决' => { :type => 'checkbox', :name => 'declined' },
        '业务经理修改或补充材料' => { :type => 'checkbox', :name => 'more_info' } 
    },
      :before_proceed => { :proceed => 'save_final_decision_maker'}

    jump :to => 'finish', :if => "${f:declined} == yes"
    jump :to => 'DD.handler', :if => '${f:more_info} == yes'

    #committee_secretary = risk_dept_examiner
    set :field => 'blade.VOTE-collect_votes_user_id', :value => '${f:blade.default_examiner_id}'
    committee_secretary :tag => 'VOTE.collect_votes', :name => '评审意见汇总',
      :custom_fields => { '业务经理修改或补充材料' => { :type => 'checkbox', :name => 'more_info_from_committee_secretary' } 
    }

    jump :to => 'DD.handler', :if => '${f:more_info_from_committee_secretary} == yes'

    risk_dept_reviewer :tag => 'VOTE.risk_review', :name => '项目复审岗复审'

    risk_dept_head :tag => 'VOTE.risk_head', :name => '风险负责人审批'

    # VP
    committee_director :tag => 'VOTE.review', :name => '主任委员审批',
      :before_edit => 'custom_fields_for_committee_director'

    jump :to => 'VOTE.notice.no_op', :if => "${f:blade.final_decision_maker_role} == committee_director"

    president :tag => 'VOTE.president', :name => '总裁审批', 
      :custom_fields => { '否决' => { :type => 'radio', :name => 'declined' },
        '同意' =>  { :type => 'radio', :name => 'agreed'}
    }

    no_op :tag => 'VOTE.notice.no_op'
    set :field => 'blade.VOTE-notice', :value => '${f:blade.default_examiner_id}'
    risk_dept_examiner :tag => 'VOTE.notice', :no_back => true

    risk_dept_head :tag => 'VOTE.notice_dispatch', :no_back => true
    completer :tag => 'finish', :name => '结束'
  end
end
