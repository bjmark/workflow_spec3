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
      :custom_fields => { '否决' => { :type => 'checkbox', :name => 'declined'}, 
        '同意报备' => { :type => 'checkbox', :name => 'agreed'}
    }
    
    business_dept_head :tag => 'other_head_review', :name => '业务负责人审批',
      :custom_fields => { '同意由报备部门进行营销' => { :type => 'checkbox', :name => 'agree_origin_dept'} } 

    jump :to => 'finish', :if => "${f:agree_origin_dept} == yes"

    business_manager :tag => 'prepare_info', :name => '准备申报资料'

    marketing_dept_staff :tag => 'marketing_dept_review2', :name => '业务管理岗复审',
      :custom_fields => { '同意' => { :type => 'radio', :name => 'choice', :value => 'other'}, 
        '由原报备部门进行营销' => { :type => 'radio', :name => 'choice', :value => 'origin'} 
    }
    
    business_manager :tag => 'start_project', :name => '业务经理立项'

    completer :tag => 'finish', :name => '结束'
  end
end
