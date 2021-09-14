require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "sinatra/content_for"
require "redcarpet"

configure do
  set :erb, :escape_html => true
  enable :sessions
  set :session_secret, 'secret'
end

root = File.expand_path("..", __FILE__)

get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def view_file(file_name)
  return file_name if Dir.children('data').include? (file_name)

  session[:error] = "#{file_name} doesn't exist"
  redirect "/"
end

get "/:filename" do
  file_path = root + "/data/" + params[:filename]
  file_name = params[:filename]
  view_file(file_name)

  if File.extname(file_name) == ".md"
    render_markdown(File.read(file_path))
  else
    headers["Content-Type"] = "text/plain"
    File.read(file_path)
  end
end