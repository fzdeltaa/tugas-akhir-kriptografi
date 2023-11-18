# app.rb
require 'sinatra'
require 'mysql2'
require 'sinatra/activerecord'
require 'digest'
require 'openssl'
require 'base64'
require 'chunky_png'
require 'rufus-scheduler'
require 'google/cloud/storage'
require_relative 'routes/main'
require_relative 'routes/index'
require_relative 'routes/decrypt'
require_relative 'routes/auth'
require_relative 'models'
require_relative 'script/reverse'
require_relative 'script/algoritma_aes'
require_relative 'script/steganodriver'
require_relative 'gcs_config'

set :database_file, 'database.yml'
