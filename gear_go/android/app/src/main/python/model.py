from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import pandas as pd
from data_fetch import fetch_all_cars, fetch_user_bookings, preprocess_data

def train_model(logs):
    """Train TF-IDF model on all cars."""
    logs.append({'text': '🧠 Training ML model...', 'color': 'green', 'icon': 'model_training'})
    cars_df = fetch_all_cars(logs)
    cars_df = preprocess_data(cars_df, logs)
    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(cars_df['features_text'])
    logs.append({'text': '✅ Model trained successfully.', 'color': 'green', 'icon': 'check_circle'})
    return vectorizer, tfidf_matrix, cars_df

def get_recommendations(user_id, logs, top_n=5):
    """Get content-based recommendations based on user's past bookings."""
    logs.append({'text': f"🔍 Generating recommendations for user: {user_id}...", 'color': 'blue', 'icon': 'person'})
    bookings = fetch_user_bookings(user_id, logs)
    if not bookings:
        logs.append({'text': "⚠️ No past bookings; returning random/popular cars.", 'color': 'orange', 'icon': 'warning'})
        cars_df = fetch_all_cars(logs)
        fallback_recs = cars_df.nlargest(top_n, 'basic_price').to_dict(orient='records')
        for rec in fallback_recs:
            logs.append({'text': f"🚗 Fallback recommended car: {rec['car_name']}", 'color': 'orange', 'icon': 'car_rental'})
        return [{k: v for k, v in rec.items() if k not in ['bookingTime', 'pickUpDateTime', 'returnDateTime']} for rec in fallback_recs]

    # Get unique booked car IDs with debug logging
    booked_car_ids = set(booking.get('documentId') for booking in bookings if 'documentId' in booking)
    logs.append({'text': f"📦 User has booked {len(booked_car_ids)} unique cars: {booked_car_ids}", 'color': 'blue', 'icon': 'list'})

    # Train model
    vectorizer, tfidf_matrix, cars_df = train_model(logs)

    # Get indices for booked cars
    logs.append({'text': f"📄 CarData documentIds: {cars_df['documentId'].tolist()}", 'color': 'purple', 'icon': 'list'})
    booked_mask = cars_df['documentId'].isin(booked_car_ids)
    booked_indices = cars_df[booked_mask].index.tolist()
    logs.append({'text': f"🔎 Booked indices: {booked_indices}", 'color': 'purple', 'icon': 'search'})
    if not booked_indices:
        logs.append({'text': "❌ No matching booked cars in dataset. Check CarData IDs.", 'color': 'red', 'icon': 'error'})
        return []

    booked_vectors = tfidf_matrix[booked_indices]
    logs.append({'text': f"📐 Booked vectors shape: {booked_vectors.shape}", 'color': 'orange', 'icon': 'timeline'})
    avg_booked_vector = np.mean(booked_vectors.toarray(), axis=0).reshape(1, -1)

    # Compute similarity
    similarities = cosine_similarity(avg_booked_vector, tfidf_matrix)
    sim_scores = list(enumerate(similarities[0]))
    sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)

    # Get top N not already booked
    rec_indices = [i for i, score in sim_scores if i not in booked_indices][:top_n]
    recommendations = cars_df.iloc[rec_indices].to_dict(orient='records')
    for rec in recommendations:
        rec_score = next((score for idx, score in sim_scores if idx == cars_df.index[cars_df['documentId'] == rec['documentId']].tolist()[0]), 0)
        logs.append({'text': f"✨ Recommended car: {rec['car_name']} (Score: {rec_score:.2f})", 'color': 'green', 'icon': 'recommend'})
    logs.append({'text': f"✅ Generated {len(recommendations)} recommendations.", 'color': 'blue', 'icon': 'done_all'})
    return [{k: v for k, v in rec.items() if k not in ['bookingTime', 'pickUpDateTime', 'returnDateTime']} for rec in recommendations]
