import argparse
import os
import sys
import boto3

def send_email(subject, body):
    region = os.getenv('AWS_REGION', 'us-east-1')
    sender = os.getenv('SES_SENDER')
    recipient = os.getenv('SES_RECIPIENT')

    if not sender or not recipient:
        print("Error: Missing SES_SENDER or SES_RECIPIENT environment variables.")
        sys.exit(1)

    try:
        ses = boto3.client('ses', region_name=region)
        ses.send_email(
            Source=sender,
            Destination={'ToAddresses': [recipient]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body}}
            }
        )
        print("Failure notification email sent successfully via SES.")
    except Exception as e:
        print(f"Failed to send email via SES: {e}")
        sys.exit(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Send pipeline failure notifications via AWS SES.")
    parser.add_argument('--event', default="DEPLOY_FAILURE", help="Event name")
    parser.add_argument('--repo', default=os.getenv('GITHUB_REPOSITORY', 'emmalux2/secure-cloud-microservices'), help="GitHub repository")
    parser.add_argument('--run', default=os.getenv('GITHUB_RUN_ID', 'unknown'), help="GitHub action run ID")

    args = parser.parse_args()

    subject = f"[{args.event}] Deployment Failed - {args.repo}"
    body = (
        f"The automated CD pipeline for repository '{args.repo}' encountered an error.\n\n"
        f"GitHub Action Run ID: {args.run}\n"
        f"View Execution Logs: https://github.com/{args.repo}/actions/runs/{args.run}"
    )

    send_email(subject, body)