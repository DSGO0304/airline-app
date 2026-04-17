import psycopg2

def get_connection():
    conn = psycopg2.connect(
        host="localhost",
        database="airline_Booking",
        user="postgres",
        password="Brunay12"
    )
    return conn