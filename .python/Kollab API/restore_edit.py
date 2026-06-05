import json
import libs.firebase_db as db

def restore(file:str):
    with open(file) as json_file:
        data = json.load(json_file)
    db.update(data, "/", "")

#restore("./2024-03-16-23-15-34.642345.json")

def edit(data):
    users =  db.read("users/")
    
    for user in users:
        if "social" not in users[user]["account_infos"]:
            db.update(data, "users/"+user+"/account_infos/",)

edit({"social":{"instagram_url":"null","discord_url":"null","soundcloud_url":"null","spotify_url":"null","tiktok_url":"null","twitch_url":"null","user_desc":"null","x_url":"null","youtube_url":"null"}})