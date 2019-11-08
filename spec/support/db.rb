require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'postgresql',
                                        database: 'has_array_of_test',
                                        host: ENV['POSTGRES_HOST'],
                                        port: ENV['POSTGRES_PORT'],
                                        min_messages: 'warning')
