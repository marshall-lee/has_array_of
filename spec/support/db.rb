require 'active_record'

ActiveRecord::Base.establish_connection(:adapter  => 'postgresql',
                                        :database => 'has_array_of_test',
                                        :min_messages => 'warning')
