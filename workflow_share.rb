# -*-_ encoding: utf-8 -*-

def merge_submit(workitem)
	my_tag = workitem.fields['params']['tag']
	hash = workitem.fields[my_tag]
	submit = workitem.fields['params']['submit']

	return submit if !hash

	submit = submit.merge(hash)
	submit.delete_if{|k,v| v == 'del'}

	return submit
end

def exec_submit(workitem,op_name)
	submit = merge_submit(workitem)

	raise 'invalid workflow operation' if !submit.has_key?(op_name)
	op = submit[op_name]

	case op
	when String
		workitem.command = op
	when Hash
		op.each do |k,v|
			if k == 'command'
				workitem.command = v
			else
				workitem.fields[k] = v
			end
		end
	end
	return workitem
end

def process(parti_name,proceed=true)
	@engine.wait_for(parti_name)
	@storage_p = @engine.storage_participant
	@workitems = @storage_p.by_participant(parti_name.to_s)
	@workitem = @workitems.first

	yield @workitem if block_given?

	@storage_p.proceed(@workitem) if proceed

	@road << parti_name
end

class Workflow1RightSetterParticipant
	include Ruote::LocalParticipant

	def on_workitem
		p = workitem.target
		workitem.fields['params']['add_right'].each do |op,role|
			p.add_right(op,role)
		end
		reply
	end
end

class Ruote::Workitem
	def target
		target = self.fields["target"]
		#target["type"].camelize.constantize.find(target["id"])
		case target["type"]
		when 'project'
			Project.find(target["id"])
		when 'cash_position'
			CashPosition.find(target['id'])
		else
			raise 'invalid target'
		end
	end
end

module WorkflowRight
	def add_right(op,role)
		hhash['overview'] ||= {}
		hhash['overview'][op] = role
	end

	def del_right(op)
		overview = (hhash['overview'] or {})

		op = [op] if op.instance_of?(String)
		op.each do |e|
			overview.delete(e)
		end
	end

	def has_right?(op,u)
		codes = u.roles.collect{|e| e.code}
		codes.include?(hhash['overview'][op])
	end
end

class Role
	attr_accessor :code
	def initialize(s)
		self.code = s
	end
end


