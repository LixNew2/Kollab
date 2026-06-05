import json, time, datetime, os
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db

CRED = credentials.Certificate('keys/adminsdk.json')
COOLDOWN = 3600

firebase_admin.initialize_app(CRED, {
    'databaseURL': ''
})

def read(reference:str):
  ref = db.reference(reference)
  try:
    return ref.get()
  except:
    return "error"

def backup():
    print(f"""
  ____          _____ _  ___    _ _____   _____ 
 |  _ \   /\   / ____| |/ / |  | |  __ \ / ____|
 | |_) | /  \ | |    | ' /| |  | | |__) | (___  
 |  _ < / /\ \| |    |  < | |  | |  ___/ \___ \ 
 | |_) / ____ \ |____| . \| |__| | |     ____) |
 |____/_/    \_\_____|_|\_\\____/|_|    |_____/ 
          
  | Every {int((COOLDOWN/60)/60)}h
""")
    old_backup = ""
    last_back_up = ""
    while True:
        #get_data
        data = read("/")

        if old_backup == "" or old_backup != data:
            with open("./backups/" + str(datetime.datetime.now()).replace(":","-").replace(" ", "-") +".json", 'w') as outfile:
                json.dump(data, outfile, indent=2)
                old_backup = data
                last_back_up = str(datetime.datetime.now()).replace(":","-").replace(" ", "-")
      
        print(str(len(os.listdir("./backups"))) + " backups completed ! | Last backup : " + last_back_up  + " | Backing up...", end='\r')
        time.sleep(COOLDOWN)
    
backup()
