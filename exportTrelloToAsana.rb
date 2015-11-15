#!/usr/bin/env ruby
 
require "rubygems"
require 'trello'
require 'asana'
require 'yaml'

cnf = YAML::load(File.open('config.yml'))

 
# Trello keys
TRELLO_DEVELOPER_PUBLIC_KEY = cnf['trello']['developer_public_key']
TRELLO_MEMBER_TOKEN = cnf['trello']['member_token']

# Asana keys
ASANA_TOKEN = cnf['asana']['personal_token']
ASANA_ASSIGNEE = 'me'
 

def get_option_from_list(list, title, attribute)
  i=0
  arr = Array.new

  while i == 0 do
    puts title
    
    list.each do |item|
      i += 1
      puts "  #{i}) #{item.send(attribute)}"
      arr << item
    end

    i = gets.chomp.to_i
    i = 0 if i <= 0 && i > list.size    
  end
  return arr[i - 1]
end

Trello.configure do |config|
  config.developer_public_key = TRELLO_DEVELOPER_PUBLIC_KEY
  config.member_token = TRELLO_MEMBER_TOKEN
end

client = Asana::Client.new do |c|
  c.authentication :access_token, ASANA_TOKEN
end

workspaces = client.workspaces.find_all

boards = Trello::Board.all
boards.each do |board|
  next if board.closed?
  
  puts "\n=== Export Board #{board.name}? [yn]"
  next unless gets.chomp == 'y' 

  # Which workspace to put it in
  workspace = get_option_from_list(workspaces, 
    "Select destination workplace", 
    "name")
  puts "Using workspace #{workspace.name}"

  # Which project to associate
  projects = client.projects.find_by_workspace(workspace: workspace.id)
  project = get_option_from_list(projects, 
    "Select destination project", 
    "name")
  puts " -- Using project #{project.name} --"

  puts ' -- Getting users --'
  users = Array.new
  users = client.users.find_all(workspace: workspace.id).take(1000) if workspace.name != "Personal Projects"


  board.lists.each do |list|
  
    puts " - #{list.name}:"

    list.cards.reverse.each do |card|
      puts "  - Card #{card.name}, Due on #{card.due}"

      # Assignee - Try to find by name. Otherwise will be empty
      assignee = "me"
      if !card.member_ids.empty? then
        userList = users.select { |u| 
          u.name == card.members[0].full_name
        }
        assignee = userList[0].id unless userList.empty?
      end
      due_on = card.due.to_date if !card.due.nil?

      # Create the task
      task = client.tasks.create(workspace: workspace.id, 
        name: card.name,
        notes: card.desc,
        due_on: due_on,
        assignee: assignee)
      
      #Project
      task.add_project(project: project.id)

      #Stories / Trello comments
      comments = card.actions.select {|a| a.type == 'commentCard'}
      comments.each do |c|
        task.add_comment(text: c.data['text'])
      end

      #Subtasks
      card.checklists.each do |checklist|
        checklist.check_items.each do |checkItem|
          task.add_subtask(name: checkItem['name'], completed: checkItem['state'] == "complete")
        end
      end

    end

     # Create each list as an aggregator if it has cards in it
    if !list.cards.empty? then
      task = client.tasks.create(workspace: workspace.id, 
        name: "#{list.name}:")
      task.add_project(project: project.id)
    end

  end

  
end
