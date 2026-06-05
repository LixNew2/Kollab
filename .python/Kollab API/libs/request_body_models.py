from pydantic import BaseModel

class Creation(BaseModel):
    pseudo: str
    normal: str
    pressed: str

class Project(BaseModel):
    project_uid: str
    project_name: str
    project_desc: str
    project_plat: str
    project_bpm: int
    project_version: int
    project_plat_version: str
    project_max_user: int
    project_date: str
    public : bool
    creator : str
    max_size : int

class Delete(BaseModel):
    lvl: int
    data: str

class Edit(BaseModel):
    project_uid: str
    project_plat : str
    project_name: str
    project_desc: str
    project_bpm: int
    project_plat_version: str
    project_max_user: int
    project_date : float
    public : bool

class Delete_user_on_project(BaseModel):
    key: str
    uid: str

class Edit_max_user_project(BaseModel):
    key: str
    max_user_project: int 

class ActiveAccount(BaseModel):
    key: str
    unique_id: str
    hostname : str
    timestemp: float

class Comment(BaseModel):
    uid: str
    key : str
    text : str
    username : str
    timestamp : str

class Social(BaseModel):
    instagram_url: str
    discord_url: str
    soundcloud_url: str
    spotify_url: str
    tiktok_url: str
    twitch_url: str
    user_desc: str
    x_url: str
    youtube_url: str