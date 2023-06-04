#!/usr/bin/env python
import os
from flask import Flask
from flask import render_template
import requests

app = Flask(__name__)


@app.route('/')
def todo():
    url = "https://mobileapi.fcc.am/FCBank.Mobile.Api/api/PublicInfo/getrates/"
    response = requests.get(url).json()["Rates"]

    usd = next(iter(
        filter(lambda x: x["Id"] == "USD", response )
        ))
    buy = usd["Buy"]
    sale = usd["Sale"]

    return render_template("index.html", usd={"buy": buy, "sale": sale})


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=os.environ.get("FLASK_SERVER_PORT", 9090), debug=True)

