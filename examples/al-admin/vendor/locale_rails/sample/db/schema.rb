ActiveRecord::Schema.define(:version => 1) do

  create_table "articles", :force => true do |t|
    t.string   "title",       :default => "", :null => false
    t.text     "description",                 :null => false
    t.date     "lastupdate"
  end

end

