from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
from app.routes import notes

app = FastAPI(title="resource-service")
Instrumentator().instrument(app).expose(app)
app.include_router(notes.router)

@app.get("/healthz")
def healthz():
    return {"status": "ok"}
