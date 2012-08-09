#encoding:utf-8
Ruote.process_definition :name => "合同关闭", :revision => "2.0.0" do
	cursor  do
		#业务部审核
		#发起人(主办或协办)
		business_manager :tag => 'step1',
			:submit => {
			'下一步:业务部负责人审核' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'}
		}

		#本业务部负责人
		business_dept_head :tag => 'step2',
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:项目审查' => nil}

		#风险部审核
		#风险管理部审查岗
		risk_dept_examiner :tag => 'step3',
			:submit => {
			"上一步:业务部负责人审核" => "jump to step2",
			"下一步:风险部负责人审核" => nil}

		#风险部负责人
		risk_dept_head :tag => 'step4',
			:submit => {
			"上一步:项目审查" => "jump to step3",
			"下一步:计财部核算岗审核" => nil}

		#计财部审核
		#业务核算岗审核
		accounting_dept_accounting_post :tag => 'step5',
			:submit => {
			"上一步:风险部负责人审核" => "jump to step4",
			"下一步:计财部负责人审核" => nil,
			"退回:发起人" => "rewind"}

		#计财部负责人审核
		accounting_dept_head :tag => 'step6',
			:submit => {
			"上一步:计财部核算岗审核" => "jump to step4",
			"下一步:分管副总裁" => nil
		}


		#分管副总裁
		vp :tag => 'step7',
			:submit => {
			"上一步:计财部负责人审核" => "jump to step6",
			"终审通过" => {'ok' => '1'},
			"终审否决" => {'ok' => '0'}}
			
		completer :tag => 'finish'
	end
end

