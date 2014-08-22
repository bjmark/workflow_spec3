#encoding:utf-8

class WorkflowHelper
  def initialize(workitem, req_params, current_user)
    @workitem = workitem
    @req_params = req_params
    @current_user = current_user
  end

  def before_edit
    return unless @workitem.params['before_edit']
    funs = @workitem.params['before_edit'].split(',').collect{|e| e.strip}
    funs.each{|m| self.send(m)}
  end

  def before_proceed(op_name)
    return unless (h = @workitem.params['before_proceed'])
    ([op_name, 'all'] & h.keys).each do |k|
      funs = h[k].split(',').collect{|e| e.strip}
      funs.each {|m| self.send(m) }
    end
  end

  def validate(op_name)
    error = []
    return error unless (h = @workitem.params['validate'])
    return error unless (s = h[op_name])
    funs = s.split(',').collect{|e| e.strip}
    funs.each{|m| error << self.send(m)}
    error.flatten
  end


  def clear_receiver
    @workitem.fields['blade'].delete('receiver_id')
  end

  def merge_submit
    my_tag = @workitem.fields['params']['tag']
    hash = @workitem.fields[my_tag]
    submit = @workitem.fields['params']['submit']

    return submit if !hash

    submit = submit.merge(hash)
    submit.delete_if{|k,v| v == 'del'}

    return submit
  end

  def exec_submit(op_name)
    submit = merge_submit

    raise 'invalid workflow operation' if !submit.has_key?(op_name)
    op = submit[op_name]

    case op
    when String
      @workitem.command = op
    when Hash
      op.each do |k,v|
        if k == 'command'
          @workitem.command = v
        else
          @workitem.fields[k] = v
        end
      end
    end
    return @workitem
  end
end

