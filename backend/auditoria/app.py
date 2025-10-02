import json, os
def handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"service": os.getenv("SERVICE","hc"), "function":"auditoria", "ok": True})
    }
