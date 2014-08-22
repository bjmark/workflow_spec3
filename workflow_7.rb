#encoding:utf-8
Ruote.process_definition :name => "合同保理", :revision => "2.0.0" do
	cursor  do
		#业务核算岗审核
		accounting_dept_accounting_post :tag => 'step1',
			:submit => {
			'下一步:计财部负责人审核' => nil,
			'取消流程' => {'command' => 'jump to finish','ok' => '2'},
			#"终审通过" => {'command' => 'jump to finish','ok' => '1'},
			#"终审否决" => {'command' => 'jump to finish','ok' => '0'},
		}

		#计财部负责人审核
		accounting_dept_head :tag => 'step2',
			:submit => {
			'上一步:业务核算岗审核' => 'rewind',
			"终审通过" => {'ok' => '1'},
			"终审否决" => {'ok' => '0'}
		}

		completer :tag => 'finish'
	end
end

