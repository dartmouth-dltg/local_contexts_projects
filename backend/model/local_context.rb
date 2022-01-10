class LocalContext < Sequel::Model(:local_context)
  include ASModel
  corresponds_to JSONModel(:local_context)

  set_model_scope :global

end
