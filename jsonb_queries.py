import psycopg2
import json

# Connect to PostgreSQL
conn = psycopg2.connect(
    host="localhost",
    port=5434,
    database="student_db",
    user="postgres",
    password="postgres"
)

cur = conn.cursor()

# Query 1: Get all students with email and phone
print("=" * 60)
print("ALL STUDENTS WITH EMAIL & PHONE")
print("=" * 60)

cur.execute("""
    SELECT 
        name,
        profile->>'email' AS email,
        profile->>'phone' AS phone
    FROM students
""")

for row in cur.fetchall():
    print(f"Name: {row[0]}, Email: {row[1]}, Phone: {row[2]}")

# Query 2: Get students with their GPA
print("\n" + "=" * 60)
print("STUDENTS WITH GPA")
print("=" * 60)

cur.execute("""
    SELECT 
        name,
        profile->'academic'->>'gpa' AS gpa,
        profile->'academic'->>'stream' AS stream
    FROM students
    ORDER BY (profile->'academic'->>'gpa')::FLOAT DESC
""")

for row in cur.fetchall():
    print(f"{row[0]:15} - GPA: {row[1]}, Stream: {row[2]}")

# Query 3: Get certifications
print("\n" + "=" * 60)
print("STUDENT CERTIFICATIONS")
print("=" * 60)

cur.execute("""
    SELECT 
        name,
        profile->'certifications' AS certs
    FROM students
""")

for row in cur.fetchall():
    certs = row[1]
    print(f"{row[0]:15} - Certifications: {', '.join(certs)}")

# Query 4: Insert new student
print("\n" + "=" * 60)
print("INSERTING NEW STUDENT")
print("=" * 60)

new_student = {
    "email": "david@example.com",
    "phone": "+91-9876543215",
    "address": {
        "street": "999 Elm St",
        "city": "Siliguri",
        "state": "West Bengal"
    },
    "academic": {
        "gpa": 3.6,
        "stream": "Science",
        "subjects": ["Physics", "Chemistry", "Biology", "Mathematics"],
        "scores": {
            "math": 91,
            "physics": 89,
            "chemistry": 90,
            "biology": 88
        }
    },
    "certifications": ["Python", "C++"],
    "sports": True
}

cur.execute("""
    INSERT INTO students (name, student_id, class, profile)
    VALUES (%s, %s, %s, %s)
""", ('David Lee', 'STU004', 11, json.dumps(new_student)))

conn.commit()
print("✓ New student inserted!")

# Query 5: Verify new student
cur.execute("""
    SELECT name, profile->>'email', profile->'academic'->>'gpa'
    FROM students
    WHERE student_id = 'STU004'
""")

row = cur.fetchone()
print(f"New student: {row[0]}, Email: {row[1]}, GPA: {row[2]}")

cur.close()
conn.close()