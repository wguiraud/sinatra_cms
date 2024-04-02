require 'redcarpet'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'tilt/erubis'

configure do 
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

root = File.expand_path("..", __FILE__)

get "/" do 
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end

  erb :index 
end

get "/:file_name" do 
  file_path = root + "/data/" + params[:file_name]

  if File.file?(file_path) 
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else 
    session[:error] = "#{params[:file_name]} doesn't exist!" 
    redirect "/" 
  end
end

