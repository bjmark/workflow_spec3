#encoding:utf-8
Ruote.process_definition :name => "五级分类2", :revision => "2.0.0" do
	cursor  do
		#发起审签
		#风险管理部资产管理岗
		risk_dept_asset_manager :tag => 'step1',
			:submit => {
			'下一步:风险管理部负责人审核' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'},
			#"终审通过" => {'command' => 'jump to finish','ok' => '1'},
			#"终审否决" => {'command' => 'jump to finish','ok' => '0'},
		}

		#风险管理部负责人
		risk_dept_head :tag => 'step2',
			:submit => {
			'上一步:发起审签' => 'rewind',
			"终审通过" => {'ok' => '1'},
			"终审否决" => {'ok' => '0'}
		}

		completer :tag => 'finish'
	end
end

