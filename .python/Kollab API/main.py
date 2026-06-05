import libs.firebase_db as db
import libs.request_body_models as request_body
import libs.base_var as base_var


import os
import shutil, datetime
from fastapi import FastAPI, Request, Depends, File, UploadFile
from fastapi.security import OAuth2PasswordBearer
from fastapi.responses import FileResponse

print("""
██╗  ██╗ ██████╗ ██╗     ██╗      █████╗ ██████╗ 
██║ ██╔╝██╔═══██╗██║     ██║     ██╔══██╗██╔══██╗
█████╔╝ ██║   ██║██║     ██║     ███████║██████╔╝
██╔═██╗ ██║   ██║██║     ██║     ██╔══██║██╔══██╗
██║  ██╗╚██████╔╝███████╗███████╗██║  ██║██████╔╝
╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═════╝ 
""")

conditons_of_use_folder = "/home/ubuntu/kollab/ConditionsOfUse/"
projects_folder = "/home/ubuntu/kollab/projects/"
'''backups_folder = "/home/ubuntu/kollab/backups/"'''
app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


@app.post("/create_account/")
async def create_account(item : request_body.Creation, token: str = Depends(oauth2_scheme)):
    if db.verify_token(token) == False:
        return "Incorrect Token"

    if db.read("users/uid", token) == None:
        #if account isn't exist
        data = base_var.base_account_data
        data['pseudo'] = item.pseudo
        data['account_infos']["account_icon"]["normal"] = item.normal
        data['account_infos']["account_icon"]["pressed"] = item.pressed

        db.set(data, "users/uid", token)
        return "created"
    return "exist"


@app.post("/create_project/")
async def create_project(item : request_body.Project, token: str = Depends(oauth2_scheme)):
    if db.verify_token(token) == False:
        return "Incorrect Token"
    if db.read("projects/" + item.project_uid, token) != None:
        return "Existing Project"

    db.update({item.project_uid : {"project_name": item.project_name, "project_desc": item.project_desc, "project_plat": item.project_plat, "project_bpm": item.project_bpm, "project_plat_version": item.project_plat_version, "project_version": item.project_version, "project_max_user": item.project_max_user, "project_max_user_edit": item.project_max_user, "project_date":item.project_date, "public" : item.public, "creator": item.creator, "upvote" : 0, "comments":{"null":"null"}, "max_size" : item.max_size}}, "projects", token)
    db.update({item.project_uid : "owner"}, "users/uid/projects", token)

    if not os.path.exists(projects_folder + item.project_uid):
        os.makedirs(projects_folder + item.project_uid)

    return 'Succes'

    
@app.post("/join_project/")
async def join_project(project_uid: str, token: str = Depends(oauth2_scheme)):
    if db.verify_token(token) == False:
        return "Incorrect Token"

    db.update({project_uid : "member"}, "users/uid/projects", token)

    return 'Succes'

"""def set_history(uid: str) -> None:
    if not os.path.exists(backups_folder + uid):
        os.makedirs(backups_folder + uid)

    history = os.listdir(backups_folder + uid)
    files_sorted = sorted(history, reverse=True)
    nbr_of_history = len(history)

    if nbr_of_history >= 5:
        try:
            os.remove(backups_folder + uid + "/" + files_sorted[-1])
        except:
            pass

    back_name = str(datetime.datetime.now()).replace(" ", "_").replace(":", "_").replace(".", "_").replace("-", "_")
    shutil.copyfile(projects_folder + uid + "/file.7z", backups_folder + uid + f"/{back_name}.7z")
    
@app.get("/get_history/")
async def get_history(uid: str):
    history = os.listdir(backups_folder + uid)
    files_sorted = sorted(history, reverse=True)
    return files_sorted

@app.get("/download_history/")
async def download_history(uid:str, filename_project : str):
    return FileResponse(path=backups_folder + uid + f"/{filename_project}.7z", filename=f"{filename_project}.7z", media_type='image/png')"""

@app.post("/upload_file/")
async def upload_file(project_uid:str, file: UploadFile):
    print(file.filename)

    with open(projects_folder + project_uid + "/file.7z", "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    return {"filename": file.filename}


@app.get("/download_file/")
async def download_file(project_uid:str):
    return FileResponse(path=projects_folder + project_uid + "/file.7z", filename="file.7z", media_type='image/png')


@app.get("/get_projects_list/")
async def get_projects_list(token: str = Depends(oauth2_scheme)):
    projects = db.read("users/uid/projects", token)
    if "null" in projects:
        projects.pop("null")

    for project in projects:
        project_type = projects[project]
        projects[project] = db.read("projects/" + project, token)
        projects[project]["type"] = project_type

    return projects


@app.get("/get_projects_infos/")
async def get_projects_infos(project_uid: str):
    if project_uid != "":
        data = db.read("projects/" + project_uid, "")
        return {"project_uid": project_uid, "project_data": data}
    else:
        return {"project_uid": project_uid, "project_data": None}   


@app.post("/push_project/")
async def push_project(project_uid:str, project_version:int, project_date : float, file: UploadFile, token: str = Depends(oauth2_scheme)):
    with open(projects_folder + project_uid + "/file.7z", "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    """set_history(project_uid)"""

    db.set(int(project_version), "projects/" + project_uid + "/project_version", token)
    db.set(float(project_date), "projects/" + project_uid + "/project_date", token)

@app.get("/get_username/")
async def get_username(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid", token)

@app.post("/delete_project/")
async def delete_project(item : request_body.Delete, token: str = Depends(oauth2_scheme)):
    user_check = db.read("/users/uid/projects", token)
    #Si c'est le créateur qui supprimer le project (se supprime de partout)
    if item.lvl == 1:
        if item.data in user_check:
            if user_check[item.data] == "owner":
                db.delete(f"/projects/{item.data}")
                try:
                    shutil.rmtree(projects_folder + item.data)
                    """shutil.rmtree(backups_folder + item.data)"""
                except:
                    pass
                for id in db.read("/users"):
                    if item.data in db.read(f"/users/{id}/projects"):
                        db.delete(f"/users/{id}/projects/{item.data}")
                        db.set(int(db.read(f"/users/{id}/account_infos/nbr_project") +1), f"/users/{id}/account_infos/nbr_project")
                return
    #Si c'est un membre qui supprimer le projet (se supprime que sur son compte)
    else:
        if item.data in user_check:
            db.delete(f"/users/uid/projects/{item.data}", token)
            return
        
@app.post("/active_account/")
async def active_account(item : request_body.ActiveAccount, token: str = Depends(oauth2_scheme)):
    keys_list = ["basic.txt", "standard.txt", "premium.txt"]
    key_current_txt = []

    for i in keys_list:
        key_current_txt.clear()
        with open("/home/ubuntu/kollab/keys/" + i) as f:
            for k in f.readlines():
                key_current_txt.append(k.replace("\n", ""))
        for ks in key_current_txt:
            if item.key == ks:
                try:
                    key_current_txt.remove(item.key)
                    with open("/home/ubuntu/kollab/keys/" + i, "w") as f:
                        for m in key_current_txt:
                            f.writelines(f"{m}\n")
                except:
                    return 0
                
                if i == "basic.txt":
                    db.set(1, "/users/uid/account_infos/activated", token)
                    db.set(10, "/users/uid/account_infos/nbr_project", token)
                    db.set(1, "/users/uid/account_infos/type", token)
                if i == "standard.txt":
                    db.set(1, "/users/uid/account_infos/activated", token)
                    db.set(20, "/users/uid/account_infos/nbr_project", token)
                    db.set(2, "/users/uid/account_infos/type", token)
                if i == "premium.txt":
                    db.set(1, "/users/uid/account_infos/activated", token)
                    db.set(30, "/users/uid/account_infos/nbr_project", token)
                    db.set(3, "/users/uid/account_infos/type", token)

                db.set(item.key, "/users/uid/account_infos/key_infos/key", token)
                db.set(item.timestemp, "/users/uid/account_infos/key_infos/timestamp", token)
                db.set(item.unique_id, "/users/uid/account_infos/unique_id", token)
                db.set(item.hostname, "/users/uid/account_infos/hostname", token)

                return 1           
    return 0               

@app.post("/active_free_trial/")
async def active_free_trial(timestemp : str, token: str = Depends(oauth2_scheme)):
    db.set(2, "/users/uid/account_infos/activated", token)
    db.set(float(timestemp), "/users/uid/account_infos/free_trial_start_time", token)
    db.set(1, "/users/uid/account_infos/nbr_project", token)

@app.get("/get_free_trial_start_time/")
async def get_free_trial_start_time(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/free_trial_start_time", token)

@app.get("/get_account_activation/")
async def get_account_activation(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/activated", token)

@app.get("/get_project_number/")
async def get_project_number(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/nbr_project", token)

@app.get("/get_project_number_active/")
async def get_project_number(token: str = Depends(oauth2_scheme)):
    user_projects = db.read("/users/uid/projects", token)
    return len(user_projects) - 1

@app.post("/edit_project_number/")
async def edit_project_number(nbr : str, token: str = Depends(oauth2_scheme)):
    db.set(int(nbr), "/users/uid/account_infos/nbr_project", token)

@app.get("/get_key_type/")
async def get_key_type(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/type", token)

@app.post("/edit_project/")
async def edit_project(item: request_body.Edit, token: str = Depends(oauth2_scheme)):
    db.update({"project_plat" : item.project_plat, "project_name": item.project_name, "project_desc": item.project_desc, "project_bpm": item.project_bpm, "project_plat_version": item.project_plat_version, "project_date":item.project_date, "public" : item.public}, "projects/" + item.project_uid, token)
    
    nombre_of_user_in_project = 0

    for i in db.read("/users"):
        if item.project_uid in db.read(f"/users/{i}/projects/"):
            nombre_of_user_in_project += 1

    db.update({"project_max_user_edit": item.project_max_user - nombre_of_user_in_project +1, "project_max_user": item.project_max_user}, "projects/" + item.project_uid, token)

@app.get("/get_users_project/")
async def get_users_project(key : str):
    user_id_list = {}

    for i in db.read("/users"):
        if key in db.read(f"/users/{i}/projects/"):
            user_id_list[str(i)] = db.read(f"/users/{i}/pseudo")

    return user_id_list

@app.get("/get_user_id/")
async def get_user_id(token: str = Depends(oauth2_scheme)):
    return db.get_uid(token)

@app.post("/delete_user_project/")
async def delete_user_project(item : request_body.Delete_user_on_project):
    projects = db.read(f"/users/{item.uid}/projects")

    for project in projects:
        if project == item.key:
            db.delete(f"/users/{item.uid}/projects/{item.key}")
            db.set(int(db.read(f"/users/{item.uid}/account_infos/nbr_project") +1), f"/users/{item.uid}/account_infos/nbr_project")
            db.set(int(db.read(f"/projects/{item.key}/project_max_user_edit") +1), f"/projects/{item.key}/project_max_user_edit")

@app.get("/get_user_icons/")
async def get_user_icons(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/account_icon", token)

@app.post("/upload_new_max_user_project/")
async def upload_new_max_user_project(item : request_body.Edit_max_user_project):
    db.set(item.max_user_project, f"/projects/{item.key}/project_max_user_edit")

@app.get("/get_project_max_users/")
async def get_project_max_users(key: str):
    return db.read(f"/projects/{key}/project_max_user_edit")

@app.get("/conditons_of_use/")
async def conditions_of_use(lang : str):
    if os.path.exists(conditons_of_use_folder + lang + ".txt"):
        with open(conditons_of_use_folder + lang + ".txt") as f:
            return f.read()
    else:
        with open(conditons_of_use_folder + "en.txt") as f:
            return  f.read()
        
@app.put("/reset_password/")
async def reset_password(email:str):
    reponse = db.reset_password(email)
    return reponse

@app.get("/get_unique_id/")
async def get_unique_id(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/unique_id", token)

@app.post("/set_unique_id/")
async def set_unique_id(unique_id : str, hostname : str, token: str = Depends(oauth2_scheme)):
    db.set(unique_id, "/users/uid/account_infos/unique_id", token)
    db.set(hostname, "/users/uid/account_infos/hostname", token)

@app.get("/get_hostname/")
async def get_unique_id(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/hostname", token)

@app.get("/get_activation_account_time/")
async def get_activation_account_time(token: str = Depends(oauth2_scheme)):
    return db.read("/users/uid/account_infos/key_infos/timestamp", token)

@app.get("/get_public_projects_list/")
async def get_public_projects_list(token: str = Depends(oauth2_scheme)):
    return_projects = {}
    projects = db.read("projects", token)
    
    if "null" in projects:
        projects.pop("null")

    for project in projects:
        if "public" in projects[project]:
            if projects[project]["public"] == True:
                return_projects[project] = projects[project]

    return return_projects

@app.post("/upvote_projets/")
async def upvote(uid : str, token: str = Depends(oauth2_scheme)) -> None:
    upvote_project = db.read(f"/projects/{uid}/upvote/")
    upvote_user = db.read("/users/uid/likes/upvotes/projects", token)
    upvoted = 0

    if uid in upvote_user:
        db.update({"upvote": upvote_project-1}, "projects/" + uid)
        db.delete(f"/users/uid/likes/upvotes/projects/{uid}", token)
    else:
        db.update({"upvote": upvote_project+1}, "projects/" + uid)
        db.update({uid: "upvoted"}, "/users/uid/likes/upvotes/projects", token)
        upvoted = 1

    return [db.read(f"/projects/{uid}/upvote"), upvoted]

@app.get("/check_project_upvote/")
async def check_project_upvote(uid : str, token: str = Depends(oauth2_scheme)) -> None:
    upvote_user = db.read("/users/uid/likes/upvotes/projects", token)
    upvoted = 0

    if uid in upvote_user:
        upvoted = 1

    return upvoted

@app.post("/set_comment/")
async def set_comment(item : request_body.Comment) -> None:
    nbr_comments = open("/home/ubuntu/kollab/comments/nbr.txt", "r").read()

    db.update({str(int(nbr_comments)+1) + "_" + item.uid: {"username" : item.username, "text" : item.text, "upvotes" : 0, "timestamp" : float(item.timestamp)}}, f"/projects/{item.key}/comments")
    open("/home/ubuntu/kollab/comments/nbr.txt", "w").write(str(int(nbr_comments)+1))

@app.get("/get_comments/")
async def get_comments(key : str) -> None:
    comments = db.read(f"/projects/{key}/comments")

    if "null" in comments:
        comments.pop("null")
    
    return comments

@app.post("/upvote_comments/")
async def upvote_comments(key : str, uid_comment : str, token: str = Depends(oauth2_scheme)) -> None:
    upvote_comment = db.read(f"/projects/{key}/comments/{uid_comment}/upvotes")
    upvote_user = db.read("/users/uid/likes/upvotes/comments", token)
    upvoted = 0

    if uid_comment in upvote_user:
        db.update({"upvotes": upvote_comment-1}, f"/projects/{key}/comments/{uid_comment}")
        db.delete(f"/users/uid/likes/upvotes/comments/{uid_comment}", token)
    else:
        db.update({"upvotes": upvote_comment+1}, f"/projects/{key}/comments/{uid_comment}")
        db.update({uid_comment: {"project" : key}}, "/users/uid/likes/upvotes/comments", token)
        upvoted = 1

    return [db.read(f"/projects/{key}/comments/{uid_comment}/upvotes"), upvoted]

@app.get("/check_comment_upvote/")
async def check_comment_upvote(uid_comment : str, token: str = Depends(oauth2_scheme)) -> None:
    upvote_user = db.read("/users/uid/likes/upvotes/comments", token)
    upvoted = 0

    if uid_comment in upvote_user:
        upvoted = 1

    return upvoted

@app.post("/delete_comment/")
async def delete_comment(uid_comment : str, key : str):
    user = db.read("/users")
    print(user)
    db.delete(f"/projects/{key}/comments/{uid_comment}")
    
    for u in user:
        if uid_comment in db.read(f"/users/{u}/likes/upvotes/comments"):
            db.delete(f"/users/{u}/likes/upvotes/comments/{uid_comment}")

@app.get("/get_time/")
async def get_time():
    return str(datetime.datetime.now()).replace(" ", "_").replace(":", "_").replace(".", "_").replace("-", "_")

@app.post("/set_social/")
async def set_social(items : request_body.Social, token: str = Depends(oauth2_scheme)):
   db.update(dict(items), "users/uid/account_infos/social", token)

@app.get("/get_social/")
async def get_social(token: str = Depends(oauth2_scheme)):
   return db.read("users/uid/account_infos/social", token)

@app.get("/get_user_public_project/")
async def get_user_public_project(token: str = Depends(oauth2_scheme)):
    return_projects = {}
    

    user_public_projet = db.read("users/uid/projects", token)
    for project in user_public_projet:
        if user_public_projet[project] == "owner":
            project_data = db.read("projects/" + project)
            if "public" in project_data:
                if project_data["public"] == True:
                    return_projects[project] = project_data
   
    return return_projects

@app.get("/get_user_social/")
async def get_user_social(key: str):
    users = db.read("users/")
    user_info = [{}]

    for user in users:
        if key in users[user]["projects"]:
            if users[user]["projects"][key] == "owner":
                user_info.append(users[user]["account_infos"]["social"])

                for project in [project for project in users[user]["projects"]]:
                    if users[user]["projects"][project] == "owner":
                        project_data = db.read("projects/" + project)
                        if "public" in project_data:
                            if project_data["public"] == True:
                                user_info[0][project] = project_data
        
                user_info.append(users[user]["account_infos"]["account_icon"]["normal"])
                user_info.append(users[user]["pseudo"])

    return user_info
       
@app.get("/check_pseudo/")
async def check_pseudo(pseudo : str):
    users = db.read("/users/")

    for user in users:
        if users[user]["pseudo"] == pseudo:
            return 1
    return 0

@app.get("/get_social_with_pseudo/")
async def get_social_with_pseudo(pseudo : str):
    users = db.read("/users/")
    user_info = [{}]

    for user in users:
        if users[user]["pseudo"] == pseudo:
            user_info.append(users[user]["account_infos"]["social"])

            for project in [project for project in users[user]["projects"]]:
                if users[user]["projects"][project] == "owner":
                    project_data = db.read("projects/" + project)
                    if "public" in project_data:
                        if project_data["public"] == True:
                            user_info[0][project] = project_data
            
            user_info.append(users[user]["account_infos"]["account_icon"]["normal"])
            user_info.append(pseudo)

    return user_info