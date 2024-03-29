require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'tilt/erubis'

configure do 
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

root = File.expand_path("..", __FILE__)

def valid_files(root)
  Dir.glob(root + "/data/*.txt").map do |path|
    File.basename(path)
  end
end

get "/" do 
  @files = valid_files(root)

  erb :index 
end

get "/:file_name" do 
  if valid_files(root).include?(params[:file_name])
    file_path = root + "/data/" + params[:file_name]
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  else 
    session[:error] = "#{params[:file_name]} doesn't exist!" unless params[:file_name] == "favicon.ico"
    redirect "/" 
  end
end

