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
    event = "DEPLOY_FAILURE"
    repo = os.getenv('GITHUB_REPOSITORY', 'emmalux2/secure-cloud-microservices')
    run_id = os.getenv('GITHUB_RUN_ID', 'unknown')

    # Parse command line flags if provided
    for i in range(len(sys.argv)):
        if sys.argv[i] == "--event" and i + 1 < len(sys.argv):
            event = sys.argv[i + 1]
        elif sys.argv[i] == "--repo" and i + 1 < len(sys.argv):
            repo = sys.argv[i + 1]
        elif sys.argv[i] == "--run" and i + 1 < len(sys.argv):
            run_id = sys.argv[i + 1]

    subject = f"[{event}] Deployment Failed - {repo}"
    body = f"The automated CD pipeline for repository '{repo}' encountered an error.\n\nGitHub Action Run ID: {run_id}\nView Execution Logs: https://github.com/{repo}/actions/runs/{run_id}"

    send_email(subject, body)