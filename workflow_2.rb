#encoding:utf-8
Ruote.process_definition :name => "头寸报备", :revision => "2.0.0" do
	cursor  do
		# "业务部审核" 
		# "发起人(主办或协办)"
		business_manager :tag => 'step1',		
			:submit => {
			'下一步:业务部负责人审核' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'}
		}

		#"本业务部负责人"
		business_dept_head :tag => 'step2',
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:项目审查' => nil}

		# "风险部审核" 
		# "项目审查岗"
		risk_dept_examiner :tag => 'step3',
			:submit => {
			"上一步:业务部负责人审核" => "jump to step2",
			"下一步:法务审核" => nil,
			"退回到发起审签" => 'rewind'
		}

		#"法务岗审核"
		risk_dept_legal_examiner :tag => 'step4', 
			:submit => {
			"上一步:项目审核" => "jump to step3",
			"下一步:风险部负责人审核" => nil,
			"退回到发起审签" => 'rewind'
		}

		#"风险部负责人"
		risk_dept_head  :tag => "step5",
			:submit => {
			"上一步:法务审核" => "jump to step4",
			"下一步:资金管理岗审核" => nil}

		# "金融市场部" 
		#"资金管理岗"
		capital_manager :tag => 'step6',
			:submit => {
			"上一步:风险部负责人审核" => "jump to step5",
			"下一步:金融市场部负责人审核" => nil}

		#"金融市场部负责人"
		capital_market_dept_head :tag => 'step7',
			:submit => {
			"上一步:资金管理岗审核" => "jump to step6",
			"终审通过" => {'ok' => '1'},
			"终审否决" => {'ok' => '0'}}

		completer :tag => 'finish'
	end
end

