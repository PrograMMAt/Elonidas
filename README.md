# Elonidas App

This is my own project.
The app lets people create their own filters for recent tweets from particular Twitter users.
For example you can only see Tweets from Elon Musk, that contain word "Tesla" and see it in your own filtered feed so that you don't have to go through other stuff you are not interested as a user.

There app has a main tab which is broken down into 2 parts -> native tab - Filtered Tweets and the other called Filters.



Sign in page
- provided by Firebase 


Filtered Tweets page
- This is the main page where you see recent tweets that meets filters you added previously
- the most recent tweet that meet the filters is shown at the top and the rest follows below
- each row shows the user account that posted the tweet, posted before time, text of the filtered tweet
- tweets are shown as soon as you sign in if there is no data - alert is shown
- if you click on a refresh button, the newest tweets (last 20 tweets from a particular user are downloaded) are downloaded and showned if they meet the filters set up on Filters tab, the tweets will be placed into the table based on time the tweet was created at
- you can also refresh the tweets with a scroll up
- you can scroll through the table 
- if you click on a sign out button the session will end and you will be logged out.
- when you click on a particular tweet it will take you to the detail of the tweet where you see jsut the text of the tweet


Active Filters page
- shows currently active filters 
- each row shows a rounded picture of a user, username that is filtered and one word that should be "watched" (filtered)
- on click plus button get to Add Filter page


Add Filter page
- there are two textfields, one for username and one for word, you want to filter
- on Add Filter button click, save the filter and get back to Active Filters, where show the new filter as well
- if the username doesn't exist it on Twitter it shows alert
- if there is no data - show alert




Installation
To run this app you will have to first install cocoapods through the terminal
Open a terminal window, and $ cd into your project directory.
Run $ pod install

if you have any troubles check the official website: https://guides.cocoapods.org/using/using-cocoapods.html

