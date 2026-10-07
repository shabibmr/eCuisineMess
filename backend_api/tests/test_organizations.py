import pytest
import uuid

def test_organization_crud(client):
    # Unique suffix to prevent test clashes
    unique_suffix = uuid.uuid4().hex[:6]
    org_name = f"Test Organization {unique_suffix}"
    trn = f"TRN-{unique_suffix}"
    
    # 1. Create Organization
    payload = {
        "org_name": org_name,
        "trn": trn,
        "address": "123 Test Street, Dubai, UAE",
        "address_to_print": "Test Org Header Ltd\nDubai, UAE",
        "address_to_print_arabic": "شركة الاختبار ذ.م.م\nدبي، الإمارات",
        "currency": "AED",
        "phone": "+971 4 000 0000",
        "email": f"test_{unique_suffix}@example.com",
        "contact_person": "Jane Doe",
        "website": "https://testorg.example.com",
        "notes": "Sample test organization",
        "is_active": 1
    }
    create_res = client.post("/api/v1/organizations", json=payload)
    assert create_res.status_code == 201, create_res.text
    org_id = create_res.json()["id"]
    assert org_id is not None

    # 2. Prevent duplicate org_name
    dup_res = client.post("/api/v1/organizations", json=payload)
    assert dup_res.status_code == 400
    assert "already exists" in dup_res.text

    # 3. Get Organization by ID
    get_res = client.get(f"/api/v1/organizations/{org_id}")
    assert get_res.status_code == 200
    org_data = get_res.json()
    assert org_data["org_name"] == org_name
    assert org_data["trn"] == trn
    assert org_data["address_to_print"] == "Test Org Header Ltd\nDubai, UAE"
    assert org_data["address_to_print_arabic"] == "شركة الاختبار ذ.م.م\nدبي، الإمارات"
    assert org_data["currency"] == "AED"
    assert org_data["phone"] == "+971 4 000 0000"
    assert org_data["contact_person"] == "Jane Doe"
    assert org_data["is_active"] == 1

    # 4. Search Filter
    search_res = client.get(f"/api/v1/organizations?search={trn}")
    assert search_res.status_code == 200
    matched = search_res.json()
    assert any(o["id"] == org_id for o in matched)

    # 5. Update Organization
    update_payload = {
        "address_to_print": "Updated Header Ltd\nAbu Dhabi, UAE",
        "currency": "USD",
        "is_active": 0
    }
    update_res = client.put(f"/api/v1/organizations/{org_id}", json=update_payload)
    assert update_res.status_code == 200
    assert update_res.json().get("success") is True

    # Verify update
    get_updated = client.get(f"/api/v1/organizations/{org_id}")
    assert get_updated.status_code == 200
    assert get_updated.json()["address_to_print"] == "Updated Header Ltd\nAbu Dhabi, UAE"
    assert get_updated.json()["currency"] == "USD"
    assert get_updated.json()["is_active"] == 0

    # 6. Delete Organization
    del_res = client.delete(f"/api/v1/organizations/{org_id}")
    assert del_res.status_code == 200

    # Verify deletion
    get_deleted = client.get(f"/api/v1/organizations/{org_id}")
    assert get_deleted.status_code == 404
