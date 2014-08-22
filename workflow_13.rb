#encoding:utf-8
Ruote.process_definition :name => "授信审批", :revision => "2.0.0" do
  cursor do
    set :field => 'blade', :value => {'helper' => 'WorkflowCreditHelper'}
    #业务部审核"
    #发起审签
    business_manager :submit => {
      '下一步:业务部负责人审批' => nil,
      '取消流程' => {'command' => 'jump to completer2','ok' => '2'}
    }

    #业务部门负责人审批
    business_dept_head  :submit => {
      '上一步:业务部业务经理' => 'jump to business_manager',
      '下一步:风险部项目复核岗派发' => nil
    }
    
    #风险部审核
    #项目复核岗派发
    risk_dept_reviewer :submit => {
      '上一步:业务部负责人审批' => 'jump to business_dept_head',
      '下一步:风险部项目审查岗审查' => nil}, 
      :form => 'form_13_1',
      :before_proceed => {
      '下一步:风险部项目审查岗审查' => 'save_examiner,remind_risk_dept_head'
    }

    #项目审查
    risk_dept_examiner :submit => {
      "上一步:风险部项目复核岗派发" => "jump to risk_dept_reviewer",
      "下一步:风险部项目复核岗复审" => nil,
      '退回:业务经理补充' => 'jump to business_manager' },
      :form => 'form_13_2',
      :before_proceed => { 
      'all' => 'clear_receiver', 
      '下一步:风险部项目复核岗复审' => 'save_examiner_suggest' 
    }

    #项目复核岗复审
    risk_dept_reviewer :tag => 'risk_dept_reviewer2',
      :submit => {
      '上一步:风险部项目审查岗审查' => 'jump to risk_dept_examiner',
      '下一步:风险部负责人审批' => nil
    }

    #风险部负责人审核
    risk_dept_head  :submit => {
      "上一步:风险部项目复核岗复审" => "jump to risk_dept_reviewer2",
      "下一步:业务部业务经理尽职调查" => nil,
      "否决" => {'command' => 'jump to completer2','ok' => '0'}
    }

    #尽职调查
    business_manager :tag => 'business_manager2',
      :submit => {
      '上一步:风险部负责人审批' => "jump to risk_dept_head",
      '下一步:业务部负责人审批' => nil,
    }

    #业务部门负责人审批
    business_dept_head  :tag => 'business_dept_head2', 
      :submit => {
      '上一步:业务部业务经理尽职调查' => 'jump to business_manager2',
      '下一步:风险部项目复核岗派发' => nil
    }

    #项目复核岗派发
    risk_dept_reviewer :tag => 'risk_dept_reviewer3',
      :submit => {
      '上一步:业务部负责人审批' => 'jump to business_dept_head2',
      '下一步:风险部项目审查岗审查' => nil},
      :form => 'form_13_1',
      :before_proceed => {
      '下一步:风险部项目审查岗审查' => 'save_examiner,remind_risk_dept_head'
    }

    #项目审查
    risk_dept_examiner :tag => 'risk_dept_examiner2', 
      :submit => {
      "上一步:风险部项目复核岗派发" => "jump to risk_dept_reviewer3",
      "下一步:风险部项目复核岗复审" => nil,
      '退回:业务经理要求修改字段' => 'jump to business_dept_head2' 
    }

    #项目复核岗复审
    risk_dept_reviewer :tag => 'risk_dept_reviewer4',
      :submit => {
      '上一步:风险部项目审查岗审查' => 'jump to risk_dept_examiner2',
      '下一步:风险部负责人审批' => nil
    }

    #风险部负责人审核
    risk_dept_head :tag => 'risk_dept_head2', 
      :submit => {
      "上一步:风险部项目复核岗复审" => "jump to risk_dept_reviewer4",
      "下一步:评审委员会秘书评审意见汇总" => nil,
      "否决" => {'command' => 'jump to completer2','ok' => '0'}
    }

    #评审委员会秘书评审意见汇总
    committee_secretary :submit => {
      "上一步:风险部负责人审批" => "jump to risk_dept_head2",
      "下一步:风险部项目复核岗复审" => nil,
      "退回:业务经理补充材料" => "jump to business_manager2",
    }

    #项目复核岗复审
    risk_dept_reviewer :tag => 'risk_dept_reviewer5',
      :submit => {
      '上一步:评审委员会秘书评审意见汇总' => 'jump to committee_secretary',
      '下一步:风险部负责人审批' => nil
    }

    #风险部负责人审核
    risk_dept_head :tag => 'risk_dept_head3', 
      :submit => {
      "上一步:风险部项目复核岗复审" => "jump to risk_dept_reviewer5",
      "下一步:主任委员审批" => nil
    }

    #主任委员审批
    committee_director :submit => {
      "上一步:风险部负责人审批" => "jump to risk_dept_head3",
      "下一步:总裁审批" => nil,
      "同意" => {'command' => 'jump to completer','ok' => '1'},
      "否决" => {'command' => 'jump to completer','ok' => '0'}
    }

    #总裁
    president :submit => {
      "上一步:主任委员审批" => "jump to committee_director",
      "同意" => {'command' => 'jump to completer','ok' => '1'},
      "否决" => {'command' => 'jump to completer','ok' => '0'}
    }

    completer 

    #项目审查岗填写通知书
    risk_dept_examiner :tag => 'risk_dept_examiner3', 
      :submit => {
      "下一步:风险管理部负责人发布通知书" => nil
    }

    #风险部负责人发布通知书
    risk_dept_head :tag => 'risk_dept_head4', 
      :submit => {
      "结束" => "jump to last_step"
    }

    completer :tag => 'completer2'

    last_step
  end
end

