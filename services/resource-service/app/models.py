from pydantic import BaseModel

class NoteIn(BaseModel):
    text: str

class Note(BaseModel):
    id: int
    text: str
