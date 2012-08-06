#encoding:utf-8
Ruote.process_definition :name => "合同审签/变更", :revision => "2.0.0" do
	cursor do
		#业务部审核"
		#发起审签
		business_manager :tag => 'step1', 
			:submit => {'下一步:业务部负责人审核' => nil}
		
		#业务部门负责人审核
		business_dept_head  :tag => 'step2', 
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:项目审查' => nil}

		#风险部审核
		#项目审查
		risk_dept_examiner :tag => 'step3', 
			:submit => {
			"上一步:业务部负责人审核" => "jump to step2",
			"下一步:法务审核" => nil}
		#法务审核
		risk_dept_legal_examiner :tag => 'step4', 
			:submit => {
			"上一步:项目审查" => "jump to step3",
			"下一步:法务复核" => nil} 
		
		#法务复核
		risk_dept_legal_reviewer :tag => 'step5', 
			:submit => {
			"上一步:法务审核" => "jump to step4",
			"下一步:风险部负责人审核" => nil},
			:action => 'workflow1_step5_edit'

		#风险部负责人审核
		risk_dept_head :tag => 'step6', 
			:submit => {
			"上一步:法务复核" => "jump to step5",
			"下一步:业务核算岗审核" => nil,
			"退回:发起人" => "rewind"},
			:action => 'workflow1_step6_edit'

		#计财部审核
		#业务核算岗审核
		accounting_dept_accounting_post :tag => 'step7', 
			:submit => {
			"上一步:风险部负责人审核" => "jump to step6",
			"下一步:计财部负责人审核" => nil}

		#计财部负责人审核
		accounting_dept_head :tag => 'step8', 
			:submit => {
			"上一步:业务核算岗审核" => "jump to step7",
			"下一步:业务经理检查会办结果" => nil,
			"退回:项目审查" => "jump to step3"}

		#业务经理检查会办结果
		business_manager :tag => 'step9', 
			:submit => {
			"上一步:计财部负责人审核" => "jump to step8",
			"下一步:业务部负责人检查会办结果" => nil}

		#业务部负责人检查会办结果
		business_dept_head :tag => 'step10', 
			:submit => {
			"上一步:业务经理检查会办结果" => "jump to step9",
			"下一步:风险管理部负责人检查会办结果" => nil,
			"退回:项目审查" => "jump to step3"}

		#风险管理部负责人检查会办结果
		risk_dept_head :tag => 'step11', 
			:submit => {
			"上一步:业务部负责人检查会办结果" => "jump to step10",
			"下一步:分管副总裁审批" => nil}

		#分管副总裁审批
		vp :tag => 'step12', 
			:submit => {
			"上一步:风险管理部负责人检查会办结果" => "jump to step11",
			"下一步:总裁审批" => nil,
			"退到:项目审查" => "jump to step3"} 

		#总裁审批
		president :tag => 'step13', 
			:submit => {"上一步:分管副总裁审批" => "jump to step12"}

		completer :tag => 'step14'

		#合同管理岗打印合同
		contract_management_post :tag => 'step15', :submit => {"完成" => nil}
	end
end
