-- Create students table with JSONB
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    student_id VARCHAR(20) UNIQUE NOT NULL,
    class INT NOT NULL,
    profile JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better JSONB query performance
CREATE INDEX idx_profile_gin ON students USING GIN(profile);

-- Sample data with flexible attributes
INSERT INTO students (name, student_id, class, profile) VALUES
(
    'Alice Johnson',
    'STU001',
    11,
    '{
        "email": "alice@example.com",
        "phone": "+91-9876543210",
        "address": {
            "street": "123 Main St",
            "city": "Siliguri",
            "state": "West Bengal",
            "country": "India",
            "zip": "734001"
        },
        "emergency_contact": {
            "name": "Mom",
            "phone": "+91-9876543211"
        },
        "academic": {
            "gpa": 3.8,
            "stream": "Science",
            "subjects": ["Physics", "Chemistry", "Biology", "Mathematics"],
            "scores": {
                "math": 95,
                "physics": 92,
                "chemistry": 88,
                "biology": 94
            }
        },
        "certifications": ["Python", "AWS"],
        "sports": true,
        "sports_details": ["Cricket", "Badminton"],
        "scholarship": true,
        "scholarship_amount": 50000
    }'::jsonb
),
(
    'Bob Smith',
    'STU002',
    11,
    '{
        "email": "bob@example.com",
        "phone": "+91-9876543212",
        "address": {
            "street": "456 Oak Ave",
            "city": "Siliguri",
            "state": "West Bengal"
        },
        "emergency_contact": {
            "name": "Dad",
            "phone": "+91-9876543213"
        },
        "academic": {
            "gpa": 3.5,
            "stream": "Commerce",
            "subjects": ["Economics", "Accounting", "Business Studies"],
            "scores": {
                "economics": 88,
                "accounting": 90,
                "business": 85
            }
        },
        "certifications": ["Excel"],
        "sports": false
    }'::jsonb
),
(
    'Carol White',
    'STU003',
    12,
    '{
        "email": "carol@example.com",
        "phone": "+91-9876543214",
        "address": {
            "street": "789 Pine Rd",
            "city": "Bengdubi",
            "state": "West Bengal"
        },
        "academic": {
            "gpa": 3.9,
            "stream": "Science",
            "subjects": ["Physics", "Chemistry", "Biology", "Mathematics", "English"],
            "scores": {
                "math": 97,
                "physics": 96,
                "chemistry": 94,
                "biology": 95,
                "english": 92
            }
        },
        "certifications": ["Python", "Java", "Docker"],
        "sports": true,
        "sports_details": ["Volleyball", "Table Tennis"],
        "scholarship": true,
        "scholarship_amount": 75000,
        "extracurricular": {
            "debating": true,
            "quizzes": true,
            "science_club": true
        }
    }'::jsonb
);

-- Create a view for easier querying
CREATE VIEW student_overview AS
SELECT 
    id,
    name,
    student_id,
    class,
    profile->>'email' AS email,
    profile->>'phone' AS phone,
    profile->'academic'->>'stream' AS stream,
    profile->'academic'->>'gpa' AS gpa
FROM students;