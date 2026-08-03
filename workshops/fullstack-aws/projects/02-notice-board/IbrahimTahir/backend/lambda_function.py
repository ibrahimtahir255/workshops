import json
import os
from datetime import datetime, timezone

from bson import ObjectId
from bson.errors import InvalidId
from pymongo import MongoClient

MONGO_HOST = os.environ.get("MONGO_HOST", "localhost")
MONGO_PORT = os.environ.get("MONGO_PORT", "27017")
MONGO_DB = os.environ.get("MONGO_DB", "notice_board")

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
}

_client = None


def get_collection():
    global _client
    if _client is None:
        _client = MongoClient(
            f"mongodb://{MONGO_HOST}:{MONGO_PORT}/",
            serverSelectionTimeoutMS=5000,
        )
    return _client[MONGO_DB]["notices"]


def _response(status_code, body=None):
    return {
        "statusCode": status_code,
        "headers": {**CORS_HEADERS, "Content-Type": "application/json"},
        "body": json.dumps(body) if body is not None else "",
    }


def _serialize(notice):
    return {
        "id": str(notice["_id"]),
        "name": notice.get("name", ""),
        "message": notice.get("message", ""),
        "createdAt": notice.get("createdAt", ""),
    }


def handle_list(collection):
    notices = collection.find().sort("createdAt", -1)
    return _response(200, [_serialize(n) for n in notices])


def handle_create(collection, event):
    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "invalid JSON body"})

    name = (payload.get("name") or "").strip()
    message = (payload.get("message") or "").strip()
    if not name or not message:
        return _response(400, {"error": "name and message are required"})

    doc = {
        "name": name,
        "message": message,
        "createdAt": datetime.now(timezone.utc).isoformat(),
    }
    result = collection.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _response(201, _serialize(doc))


def handle_delete(collection, notice_id):
    try:
        object_id = ObjectId(notice_id)
    except InvalidId:
        return _response(400, {"error": "invalid notice id"})

    result = collection.delete_one({"_id": object_id})
    if result.deleted_count == 0:
        return _response(404, {"error": "notice not found"})
    return _response(204)


def lambda_handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")

    if method == "OPTIONS":
        return _response(200)

    try:
        collection = get_collection()

        if method == "GET":
            return handle_list(collection)

        if method == "POST":
            return handle_create(collection, event)

        if method == "DELETE":
            notice_id = (event.get("pathParameters") or {}).get("id")
            if not notice_id:
                return _response(400, {"error": "notice id is required"})
            return handle_delete(collection, notice_id)

        return _response(405, {"error": f"method {method} not allowed"})

    except Exception as exc:  # noqa: BLE001 - surface as 500 for API Gateway/CloudWatch
        return _response(500, {"error": str(exc)})
