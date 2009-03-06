class Product < ActiveRecord::Base
  xss_terminate :sanitize => [:description], :tags => %{a}, :attributes => %{href}
end
