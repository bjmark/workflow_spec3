#encoding:utf-8
Ruote.process_definition :name => "租后检查", :revision => "2.0.0" do
	cursor  do
		#业务部审核"
		#发起审签
		business_manager :tag => 'step1', 
			:submit => {
			'下一步:业务部负责人审核' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'},
			#"终审通过" => {'command' => 'jump to finish','ok' => '1'},
			#"终审否决" => {'command' => 'jump to finish','ok' => '0'},
		}

		#业务部门负责人审核
		business_dept_head  :tag => 'step2', 
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:风险部资产管理岗审核' => nil}

		#风险管理部资产管理岗
		risk_dept_asset_manager :tag => 'step3',
			:submit => {
			'上一步:发起审签' => 'jump to step2',
			'下一步:风险部负责人审核' => nil}

		#风险管理部负责人
		risk_dept_head :tag => 'step4',
			:submit => {
			'上一步:风险部资产管理岗审核' => 'jump to step3',
			"签收租后检查报告" => {'ok' => '1'},
			"退回业务部门" => 'jump to step1'
		}

		completer :tag => 'finish'
	end
end

