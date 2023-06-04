import requests


url = "https://mobileapi.fcc.am/FCBank.Mobile.Api/api/PublicInfo/getrates/"
response = requests.get(url).json()["Rates"]

usd = next(iter(
    filter(lambda x: x["Id"] == "USD", response )
    ))
buy = usd["Buy"]
sale = usd["Sale"]

print(buy)
print(sale)