# app.py
from flask import Flask, request, jsonify
import logging
from model import get_recommendations

app = Flask(__name__)

# Set up logging to capture ML process logs
log_handler = logging.StreamHandler()
log_handler.setLevel(logging.INFO)
app.logger.addHandler(log_handler)
app.logger.setLevel(logging.INFO)

logs = []  # List to store dynamic logs

@app.before_request
def clear_logs():
    logs.clear()  # Clear logs before each request to capture fresh ones

@app.route('/recommend', methods=['GET'])
def recommend():
    user_id = request.args.get('user_id')
    if not user_id:
        app.logger.error("No user_id provided.")
        return jsonify({'error': 'user_id required'}), 400
    app.logger.info(f"Received request for recommendations: user_id={user_id}")
    recs = get_recommendations(user_id, logs)  # Pass logs to capture inside the function
    app.logger.info("Sending response.")
    return jsonify({'recommendations': recs, 'logs': logs})  # Return logs with recommendations

if __name__ == '__main__':
    print("Starting Flask API server...")
    app.run(debug=True, host='0.0.0.0', port=5000)  # Ensure accessible from emulator