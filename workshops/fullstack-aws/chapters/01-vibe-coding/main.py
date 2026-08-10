# A minimal FastAPI app: Hello World + a simple in-memory Users API.
# No database, no auth, no config files — just enough to learn the basics.

from fastapi import FastAPI
from pydantic import BaseModel

# Create the FastAPI application instance.
# This "app" object is what uvicorn runs.
app = FastAPI()


# Describes the shape of the JSON body clients send to create a user.
# FastAPI uses this to validate incoming requests automatically.
class UserIn(BaseModel):
    name: str
    email: str


# In-memory "database": just a plain Python list.
# Data lives only in RAM and disappears every time the server restarts.
users = []

# Keeps track of the next id to assign. Starts at 1 and goes up by 1
# each time a new user is created (a simple stand-in for auto-increment).
next_id = 1


@app.get("/")
def read_root():
    # A simple health-check / welcome route.
    return {"message": "Hello World"}


@app.post("/users")
def create_user(user: UserIn):
    # FastAPI parses the JSON request body into a UserIn object for us,
    # checking that "name" and "email" are present and are strings.
    global next_id

    # Build the new user as a plain dictionary, adding a generated id.
    new_user = {"id": next_id, "name": user.name, "email": user.email}

    # Save it in our in-memory list.
    users.append(new_user)

    # Move the id counter forward for the next user.
    next_id += 1

    # Return the user we just created, including its new id.
    return new_user


@app.get("/users")
def list_users():
    # Just return everything we've stored so far.
    return users
