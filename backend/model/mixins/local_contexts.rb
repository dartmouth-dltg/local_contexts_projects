module LocalContexts

  def self.included(base)
    base.one_to_many :local_context

    base.def_nested_record(:the_property => :local_context,
                           :contains_records_of_type => :local_context,
                           :corresponding_to_association  => :local_context,
                           :is_array => false)
  end

end
