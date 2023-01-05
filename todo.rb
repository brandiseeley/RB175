# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

require 'securerandom'
secret = SecureRandom.hex(32)

configure do
  enable :sessions
  set :session_secret, secret
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

# VIEW HELPERS
helpers do
  def all_complete?(list)
    !list[:todos].any? { |todo| todo[:completed] == false }
  end

  def empty_list?(list)
    list[:todos].empty?
  end
end

# returns an array of list names
def list_names
  lists = session[:lists]
  lists.map { |list| list[:name] }
end

# returns a boolean representing validity of given list name
def valid_name?(name)
  error_message(name) == 'no error'
end

def valid_todo?(text)
  !( text.strip.empty? || !(1..100).cover?(text.strip.length) )
end

# returns error message for invalid list name, or "no error" if name is valid
def error_message(name)
  if !(1..100).cover?(name.length)
    return 'List name must be between 1 and 100 characters.'
  elsif list_names.include?(name)
    return "'#{name}' is already a list. Name must be unique."
  end

  'no error'
end

# generate unique id
def generate_id
  session[:current_id] = 0 if session[:current_id].nil?
  id = session[:current_id]
  session[:current_id] += 1
  id
end

# select list based on given id
def select_list(id)
  @lists.select { |list| list[:id] == id }.first
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists
end

# Render 'new list' form
get '/lists/new' do
  erb :new_list
end

# get specific list or create new list
get '/lists/:list_id' do
  @list = select_list(params[:list_id].to_i)
  erb :list
end

# edit an existing todo list
get '/lists/:list_id/edit' do
  @id = params[:list_id].to_i
  @list = select_list(@id)
  erb :edit_list
end


# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  if valid_name?(list_name)
    session[:lists] << { name: list_name, todos: [] , id: generate_id}
    session[:success] = 'The list has been created.'
    redirect '/lists'
  else
    session[:error] = error_message(list_name)
    erb :new_list
  end
end

# Change list name
post '/lists/:list_id/edit' do
  new_list_name = params[:list_name].strip
  id = params[:list_id].to_i
  @list = select_list(id)
  old_name = @list[:name]

  if valid_name?(new_list_name)
    @list[:name] = new_list_name
    session[:success] = "The list '#{old_name}' has been renamed to '#{new_list_name}'"
    redirect "/lists/#{id}"
  else
    session[:error] = error_message(new_list_name)
    erb :edit_list
  end
end

# delete list
post '/lists/:list_id/destory' do
  list = select_list(params[:list_id].to_i)
  list_name = list[:name]
  @lists.delete(list)
  session[:success] = "'#{list_name}' has been deleted."
  redirect "/lists"
end

# add todo item to list
post '/lists/:list_id/todos' do
  puts "the todo item entered is:#{params[:todo]}"
  @list = select_list(params[:list_id].to_i)
  if valid_todo?(params[:todo])
    @list[:todos] << { name: params[:todo].strip, completed: false }
    session[:success] = "The todo was added"
    redirect "/lists/#{params[:list_id]}"
  else
    session[:error] = "Todo must be between 1 and 100 characters."
    erb :list
  end
end

# delete a todo item from list
post '/lists/:list_id/todos/:todo_id/destroy' do
  @list = select_list(params[:list_id].to_i)
  @list[:todos].delete_at(params[:todo_id].to_i)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{params[:list_id]}"
end

# toggle completion of todo item
post '/lists/:list_id/todos/:todo_id' do
  @list = select_list(params[:list_id].to_i)
  @todo = @list[:todos][params[:todo_id].to_i]
  is_completed = params[:completed] == "true"
  @todo[:completed] = is_completed
  redirect "/lists/#{params[:list_id]}"
end

# mark all todos in list as complete
post '/lists/:list_id/complete_all' do
  @list = select_list(params[:list_id].to_i)
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been completed."
  redirect "/lists/#{params[:list_id]}"
end
