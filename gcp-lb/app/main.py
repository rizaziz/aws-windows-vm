import functions_framework
from flask import redirect, render_template
from base64 import b64encode

@functions_framework.http
def hello_get(request):
    """HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    Note:
        For more information on how Flask integrates with Cloud
        Functions, see the `Writing HTTP functions` page.
        <https://cloud.google.com/functions/docs/writing/http#http_frameworks>
    """
    
    binary_png = None
    with open("favicon.jpg", "rb") as f:
        binary_png = f.read()

    encoded_png = str(b64encode(binary_png), encoding='utf-8')
    return render_template('index.html', base64_encoded_png=encoded_png)
   
