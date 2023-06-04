import requests


data = requests.get("https://rate.am/")
print(data.text)
