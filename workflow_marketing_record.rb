#encoding:utf-8

Ruote.process_definition :code => 'marketing_record', :name => "营销报备",
  :version => "1.0.0", :target_model => 'Proposal' do
  cursor do
    set :field => 'blade', :value => {}
    set :field => 'blade.helper', :value => 'WorkflowMarketingRecordHelper' 
    
    business_manager :tag => 'handler', :name => '业务经理发起申报'
    business_dept_head :tag => 'head_review', :name => '业务负责人审批',
      :custom_fields => { '否决' => { :type => 'checkbox', :name => 'declined'} }
    
    jump :to => 'finish', :if => "${f:declined} == yes"
    
    marketing_dept_staff :tag => 'marketing_dept_review', :name => '业务管理岗审批',
      :in_form => 'in_form_marketing_record',
      :custom_fields => { '否决' => { :type => 'checkbox', :name => 'declined'}, 
        '同意报备' => { :type => 'checkbox', :name => 'agreed'},
        '退回给发起人' => { :type => 'checkbox', :name => 'back_to_handler'}
    },:before_edit => 'prepare_business_dept',
      :before_proceed => {:proceed => 'save_business_dept'}

    jump :to => 'finish', :if => "${f:declined} == yes"
    jump :to => 'start_project', :if => "${f:agreed} == yes"
    jump :to => 'handler', :if => "${f:back_to_handler} == yes"

    set :field => 'blade.other_head_review_user_id', :value => '${f:blade.other_business_dept_id}'
    business_dept_head :tag => 'other_head_review', :name => '业务负责人审批',
      :in_form => 'in_form_marketing_record_2',
      :custom_fields => { '同意由报备部门进行营销' => { :type => 'checkbox', :name => 'agree_origin_dept'} 
    },:before_edit => 'prepare_business_manager',
      :before_proceed => {:proceed => 'save_business_manager if agree_origin_dept == no'}

    jump :to => 'marketing_dept_review2', :if => "${f:agree_origin_dept} == yes"

    set :field => 'blade.prepare_info_user_id', :value => '${f:blade.other_dept_business_manager_id}'
    business_manager :tag => 'prepare_info', :name => '准备申报资料'

    marketing_dept_staff :tag => 'marketing_dept_review2', :name => '业务管理岗复审',
      :custom_fields => { '同意' => { :type => 'radio', :name => 'choice', :value => 'other'}, 
        '由原报备部门进行营销' => { :type => 'radio', :name => 'choice', :value => 'origin'} 
    }

    set :field => 'blade.start_project_user_id', :value => '${f:blade.other_dept_business_manager_id}', :if => '${f:choice} == other' 
    business_manager :tag => 'start_project', :name => '业务经理立项'

    completer :tag => 'finish', :name => '结束'
  end
end
