#encoding:utf-8
Ruote.process_definition :name => "资金调拔", :revision => "2.0.0" do
	cursor  do
		#金融市场部
		#资金管理岗
		capital_manager :tag => 'step1',
			:submit => {
			'下一步:金融市场部负责人' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'}
		}

		#金融市场部负责人
		capital_market_dept_head :tag => 'step2',
			:submit => {
			'上一步:发起审签' => 'jump to step1',
			'下一步:业务核算岗审核' => nil,
		}

		#计财部审核
		#业务核算岗审核
		accounting_dept_accounting_post :tag => 'step3',
			:submit => {
			'上一步:金融市场部负责人' => 'jump to step2',
			'下一步:计财部负责人审核' => nil,
		}
		
		#计财部负责人审核
		accounting_dept_head :tag => 'step4',
			:submit => {
			'上一步:业务核算岗审核' => 'jump to step3',
			"终审通过" => {'ok' => '1'},
			"终审否决" => {'ok' => '0'}
		}

		completer :tag => 'finish'
	end
end

