import requests as req
import json
from bs4 import BeautifulSoup
import boto3
from datetime import datetime, timezone
from botocore.exceptions import ClientError

S3_BUCKET = 'agricultural-helper'
S3_KEY = 'output.json'
REGION = 'us-east-2'

s3 = boto3.client('s3', region_name=REGION)

def scrape_news():
    url = "https://nongnghiep.vn/"
    res = req.get(url, timeout=10)
    soup = BeautifulSoup(res.text, 'html.parser')

    title = [a.get_text(strip=True) for a in soup.select('li.news-home-item h3 a')]
    link = [a['href'] for a in soup.select('li.news-home-item > a[href]')]
    des = [p.get_text(strip=True) for p in soup.select('li.news-home-item p')]
    image = [img['src'] for img in soup.select('li.news-home-item a img[src]')]

    data = [
        {
            "title": title[i],
            "image": image[i],
            "description": des[i],
            "link": link[i]
        } for i in range(min(len(title), len(image), len(des), len(link)))
    ]
    return data

def upload_to_s3(data):
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=S3_KEY,
        Body=json.dumps(data, ensure_ascii=False),
        ContentType='application/json'
    )

def download_from_s3():
    obj = s3.get_object(Bucket=S3_BUCKET, Key=S3_KEY)
    return json.loads(obj['Body'].read())

def is_cache_expired():
    try:
        obj = s3.head_object(Bucket=S3_BUCKET, Key=S3_KEY)
        last_modified = obj['LastModified']
        now = datetime.now(timezone.utc)
        return (now - last_modified).days >= 1
    except ClientError as e:
        return True

def lambda_handler(event, context):
    if is_cache_expired():
        data = scrape_news()
        upload_to_s3(data)
    else:
        data = download_from_s3()
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(data, ensure_ascii=False)
    }
