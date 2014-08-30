# encoding:utf-8
#
Ruote.process_definition :code => 'credit_approval', :name => "授信审批",
  :version => "1.0.0", :target_model => 'Proposal' do
  cursor do
    set :field => 'blade', :value => {}
    set :field => 'blade.helper', :value => 'WorkflowCreditApprovalHelper' 

    business_manager :tag => 'INIT.handler', :name => '主办或协办立项申请'
    business_dept_head :tag => 'INIT.head_review', :name => '业务负责人审批',
      :custom_fields => [
        { :type => 'checkbox', :name => 'declined', :label => '否决' }
    ]

    set :field => 'decision', :value=> 'declined', :if => "${f:declined}"
    jump :to => 'finish', :if => "${f:declined}"

    risk_dept_reviewer :tag => 'INIT.risk_dispatch', :name => '项目复审岗派发',
      :in_form => 'in_form_13_1',
      :before_proceed => {
      :proceed => 'save_examiner, remind_risk_dept_head'
    }

    risk_dept_examiner :tag => 'INIT.risk_exam', :name => '立项审查',
      :custom_fields => [{ :type => 'checkbox', :name => 'more_info', :label => '修改或补充材料' }],
      :form => 'form_13_2',
      :before_proceed => {:all => 'clear_receiver',
        :proceed => 'save_examiner_suggest if !more_info'
    }

    jump :to => 'INIT.handler', :if => '${f:more_info}'

    risk_dept_reviewer :tag => 'INIT.risk_review', :name => '项目复核岗复核',
      :before_proceed => {:return => 'set_receiver'}

    risk_dept_head :tag => 'INIT.risk_head_review', :name => '风险负责人审批',
      :custom_fields => [
        { :type => 'checkbox', :name => 'declined', :label => '否决' }
    ]
    jump :to => 'finish', :if => "${f:declined}"

    business_manager :tag => 'DD.handler', :name => '尽职调查'
    business_dept_head :tag => 'DD.head_review', :name => '业务部负责人审批'

    risk_dept_reviewer :tag => 'DD.risk_dispatch', :name => '项目复审岗派发',
      :in_form => 'in_form_13_1',
      :before_proceed => {
      :proceed => 'save_examiner, remind_risk_dept_head'
    }

    risk_dept_examiner :tag => 'DD.risk_examine', :name => '项目审查',
      :custom_fields => [{ :type => 'checkbox', :name => 'more_info', :label => '修改或补充材料' }],
      :in_form => 'in_form_13_3',
      :before_proceed => { :proceed => 'save_final_decision_maker',
        :all => 'clear_receiver'}
    
    jump :to => 'DD.handler', :if => '${f:more_info}'

    risk_dept_reviewer :tag => 'DD.risk_review', :name => '项目复核岗复审',
      :in_form => 'in_form_13_3',
      :before_proceed => {:return => 'set_receiver',
        :proceed => 'save_final_decision_maker'}

    risk_dept_head :tag => 'VOTE.risk_head', :name => '负责人审批',
      :in_form => 'in_form_13_3',
      :custom_fields => [
        { :type => 'checkbox', :name => 'declined', :label => '否决' },
        { :type => 'checkbox', :name => 'more_info', :label => '业务经理修改或补充材料' }],
      :before_proceed => { :proceed => 'save_final_decision_maker'}

    jump :to => 'finish', :if => "${f:declined}"
    jump :to => 'DD.handler', :if => '${f:more_info}'

    committee_secretary :tag => 'VOTE.collect_votes', :name => '评审意见汇总',
      :more_info => 'DD.handler'

    risk_dept_reviewer :tag => 'VOTE.risk_review', :name => '项目复审岗复审'
    risk_dept_head :tag => 'VOTE.risk_head', :name => '风险负责人审批'

    # VP
    committee_director :tag => 'VOTE.review', :name => '主任委员审批'

    jump :to => 'VOTE.notice', :if => "${f:final_decision} == yes"
    jump :to => 'VOTE.notice', :if => "${f:final_decision} == no"

    president :tag => 'VOTE.president', :name => '总裁审批', 
      :custom_fields => [
        { :type => 'radio', :name => 'final_decision', :value => 'yes', :label => '否决' },
        { :type => 'radio', :name => 'final_decision', :value => 'no', :label => '同意' }
    ]

    risk_dept_reviewer :tag => 'VOTE.notice'
    risk_dept_head :tag => 'VOTE.notice_dispatch'
    completer :tag => 'finish', :name => '结束'
  end
end
