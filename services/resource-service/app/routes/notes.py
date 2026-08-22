from fastapi import APIRouter, Depends
from app.auth import verify_token
from app.models import Note, NoteIn

router = APIRouter(prefix="/notes", tags=["notes"])
_db: dict[str, list[Note]] = {}

@router.get("/")
def list_notes(user: dict = Depends(verify_token)):
    return _db.get(user["sub"], [])

@router.post("/")
def create_note(note: NoteIn, user: dict = Depends(verify_token)):
    user_notes = _db.setdefault(user["sub"], [])
    new_note = Note(id=len(user_notes) + 1, text=note.text)
    user_notes.append(new_note)
    return new_note
