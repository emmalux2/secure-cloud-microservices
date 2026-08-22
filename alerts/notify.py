import argparse
import os
import boto3

def send_email(subject: str, body: str):
    ses = boto3.client("ses", region_name=os.environ.get("AWS_REGION", "us-east-1"))
    ses.send_email(
        Source=os.environ["SES_SENDER"],
        Destination={"ToAddresses": [os.environ["SES_RECIPIENT"]]},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body}},
        },
    )

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--event", required=True)
    parser.add_argument("--repo", default="")
    parser.add_argument("--run", default="")
    args = parser.parse_args()

    subject = f"[SecureCloud] {args.event}"
    body = f"Event: {args.event}\nRepo: {args.repo}\nRun: {args.run}\n"
    send_email(subject, body)
    print("Notification email sent.")
