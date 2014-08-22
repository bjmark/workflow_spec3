#encoding:utf-8
Ruote.process_definition :name => "合同审签", :revision => "2.0.0" do
	cursor do
		#业务部审核"
		#发起审签
		no_op :tag => 'step1'
		right_setter :add_right => {
			'update_project' => 'business_manager'
		}

		business_manager :on_leave => {
			'del_right' => 'update_project'},
			:submit => {
			'下一步:业务部负责人' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'},
			#"终审通过" => {'command' => 'jump to finish','ok' => '1'},
			#"终审否决" => {'command' => 'jump to finish','ok' => '0'}
		}
		
		#业务部门负责人审核
		business_dept_head  :tag => 'step2', 
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:项目审查岗' => nil}

		#风险部审核
		#项目审查
		risk_dept_examiner :tag => 'step3', 
			:submit => {
			"上一步:业务部负责人" => "jump to step2",
			"下一步:法务审核岗" => nil,
			'退回:发起审签' => 'rewind'
		}

		#法务审核,有权修改逾期日利率，合同编号，是否填报，合同上传
		no_op :tag => 'step4'
		right_setter :add_right => {
			'edit_overdue_day_rate' => 'risk_dept_legal_examiner',
			'update_contract_number' => 'risk_dept_legal_examiner',
			'leaseship_is_fill' => 'risk_dept_legal_examiner',
			'create_business_contract' => 'risk_dept_legal_examiner',
		}

		risk_dept_legal_examiner :validate => 'workflow1_validate',
			:on_leave => { 'del_right' => ['edit_overdue_day_rate','update_contract_number',
				'leaseship_is_fill','create_business_contract'],
				},
				:submit => {
			"上一步:项目审查" => "jump to step3",
			"下一步:法务复核" => nil,
			'退回:发起审签' => 'rewind'
		} 

		#法务复核
		risk_dept_legal_reviewer :tag => 'step5', 
			:submit => {
			"上一步:法务审核" => "jump to step4",
			"下一步:风险部负责人" => nil},
			:action => 'workflow1_step5'

		#风险部负责人审核
		risk_dept_head :tag => 'step6', 
			:submit => {
			"上一步:法务复核岗" => "jump to step5",
			"下一步:业务核算岗" => nil,
			"退回:发起人" => "rewind"},
			:action => 'workflow1_step6'

		#计财部审核
		#业务核算岗审核,有权修改调息方式
		no_op :tag => 'step7'
		right_setter :add_right => {
			'edit_rate_adjustment_type' => 'accounting_dept_accounting_post',
			'update_amortization_type' => 'accounting_dept_accounting_post'
		}
		accounting_dept_accounting_post :on_leave => {
			'del_right' => ['edit_rate_adjustment_type','update_amortization_type']}, 
			:submit => {
			"上一步:风险部负责人" => "jump to step6",
			"下一步:计财部负责人" => nil}

		#计财部负责人审核
		accounting_dept_head :tag => 'step8', 
			:submit => {
			"上一步:业务核算岗" => "jump to step7",
			"下一步:业务经理检查会办结果" => nil,
			"退回:法务审核岗" => "jump to step4"}

		#业务经理检查会办结果
		business_manager :tag => 'step9', 
			:submit => {
			"上一步:计财部负责人" => "jump to step8",
			"下一步:业务部负责人检查会办结果" => nil}

		#业务部负责人检查会办结果
		business_dept_head :tag => 'step10', 
			:submit => {
			"上一步:业务经理检查会办结果" => "jump to step9",
			"下一步:风险管理部负责人检查会办结果" => nil,
			"退回:法务审核" => "jump to step4"}

		#风险管理部负责人检查会办结果
		risk_dept_head :tag => 'step11', 
			:submit => {
			"上一步:业务部负责人检查会办结果" => "jump to step10",
			"下一步:分管副总裁" => nil}

		#分管副总裁审批
		vp :tag => 'step_vp', 
			:submit => {
			"上一步:风险管理部负责人检查会办结果" => "jump to step11",
			"下一步:总裁" => nil,
			"退到:法务审核岗" => "jump to step4"} 

		#总裁审批
		president :tag => 'step_president', 
			:submit => {
			"上一步:分管副总裁" => "jump to step_vp",
			"终审通过" => {'command' => 'jump to finish','ok' => '1'},
			"终审否决" => {'command' => 'jump to finish','ok' => '0'}
		}

		completer :tag => 'finish'
		
		#terminate :if => '${f:ok} == 0'
		#terminate :if => '${f:ok} == 2'
		
		#合同管理岗打印合同
		#contract_management_post :tag => 'step15', :submit => {"完成" => nil}
		#completer2 
	end
end
