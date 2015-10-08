Export Trello Board to Asana
===============
This ruby script allows you to load an Asana project with cards defined in a Trello Board.

Each list in the Trello Board will be a section in the Asana Project.
This script is meant to support one time migration operations, so no effort has been put into making this be able to run over the same board and detect what has been migrated, or even facilitating the login/session creation process. Just go to a couple of URLs (described below), and get some tokens to run the script.

config.yml
---------------
You'll need to create a config.yml file with your Asana key and Trello API.
A template config.EXAMPLE.yml is provided for your reference. Copy it to config.yml.

To get your Trello developer key you should login to Trello and go to https://trello.com/1/appKey/generate.
The first value (Key) is what you should use for the developer_public_key setting

You'll also need the token to login to the API. No interactive authentication is supported on this console application. So you'll also need a token to use for the API usage session.
To get it go to https://trello.com/1/authorize?key=YOUR_DEVELOPER_PUBLIC_KEY&name=ExportTasksToAsana&response_type=token
It will grant you a token valid for 30 days, which you can set in the config.yml file.

