import firebase_admin, pyrebase
from firebase_admin import credentials
from firebase_admin import db
from firebase_admin import auth
from firebase_admin import messaging

cred = credentials.Certificate('keys/adminsdk.json')

firebaseConfg={'apiKey': "",
               'authDomain': "",
               'databaseURL': "",
               'projectId': "",
               'storageBucket': "",
               'messagingSenderId': "",
               'appId': "",
               'measurementId': ""}

firebase = pyrebase.initialize_app(firebaseConfg)
auth_pyrebase = firebase.auth()

firebase_admin.initialize_app(cred, {
    'databaseURL': ''
})


def get_uid(token:str):
  data = auth.verify_id_token(token)['uid']
  return data


def verify_token(token: str):
    try:
        data = auth.verify_id_token(token)
        return {"uid" : data["uid"]}
    except:
        return "error"


def read(reference:str, token:str=""):
  if "uid" in reference:
    reference = reference.replace("uid", get_uid(token))
  ref = db.reference(reference)
  try:
    return ref.get()
  except:
    return "error"


def set(data, reference:str, token:str=""):
  if "uid" in reference:
    reference = reference.replace("uid", get_uid(token))
  users_ref = db.reference(reference)
  return users_ref.set(data)


def update(data, reference:str, token:str=""):
  if "uid" in reference:
    reference = reference.replace("uid", get_uid(token))
  users_ref = db.reference(reference)
  return users_ref.update(data)

def delete(reference:str, token:str=""):
  if "uid" in reference:
    reference = reference.replace("uid", get_uid(token))
  ref = db.reference(reference)
  try:
    ref.delete()
  except:
    return "error"
   
def reset_password(email:str):
  try:
    auth_pyrebase.send_password_reset_email(email)
  except:
    return "error"
  return "send"