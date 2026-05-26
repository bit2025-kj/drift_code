import os
import sys
# Add backend directory to path so we can import app modules
sys.path.append(r"c:\Users\Ce pc\Desktop\drift_code\backend")
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
# Set mock environment variable before imports if necessary
os.environ["SECRET_KEY"] = "test-secret-key-for-unit-testing-purposes"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
from app.main import app
from app.utils.auth import create_access_token, create_refresh_token, decode_token
from app.config import settings
def test_token_differentiation():
    print("Testing token type differentiation...")
    user_id = "test-user-id"
    access_token = create_access_token(user_id)
    refresh_token = create_refresh_token(user_id)
    
    # 1. Access token decoded as access token should succeed
    decoded_access = decode_token(access_token, expected_type="access")
    assert decoded_access == user_id
    print("✅ Access token decoded as access token successfully")
    
    # 2. Refresh token decoded as refresh token should succeed
    decoded_refresh = decode_token(refresh_token, expected_type="refresh")
    assert decoded_refresh == user_id
    print("✅ Refresh token decoded as refresh token successfully")
    
    # 3. Access token decoded as refresh token should fail
    try:
        decode_token(access_token, expected_type="refresh")
        assert False, "Access token accepted as refresh token!"
    except Exception as e:
        print(f"✅ Access token rejected as refresh token (as expected): {e.detail}")
        
    # 4. Refresh token decoded as access token should fail
    try:
        decode_token(refresh_token, expected_type="access")
        assert False, "Refresh token accepted as access token!"
    except Exception as e:
        print(f"✅ Refresh token rejected as access token (as expected): {e.detail}")
def test_forgot_password_demo_code():
    print("\nTesting forgot-password demo_code settings...")
    
    # Mock db dependency
    mock_db = MagicMock()
    mock_user = MagicMock()
    mock_user.email = "test@example.com"
    
    # Mock execute result
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_user
    mock_db.execute.return_value = mock_result
    
    from app.database import get_db
    app.dependency_overrides[get_db] = lambda: mock_db
    
    client = TestClient(app)
    
    # Case A: DEBUG is True
    settings.DEBUG = True
    response = client.post("/auth/forgot-password", json={"email": "test@example.com"})
    assert response.status_code == 200
    data = response.json()
    assert data["demo_code"] is not None
    print(f"✅ DEBUG=True: demo_code is visible: {data['demo_code']}")
    
    # Case B: DEBUG is False
    settings.DEBUG = False
    response = client.post("/auth/forgot-password", json={"email": "test@example.com"})
    assert response.status_code == 200
    data = response.json()
    assert data.get("demo_code") is None
    print("✅ DEBUG=False: demo_code is hidden/None")
    
    app.dependency_overrides.clear()
if __name__ == "__main__":
    try:
        test_token_differentiation()
        test_forgot_password_demo_code()
        print("\n🎉 All tests completed successfully!")
    except AssertionError as ae:
        print(f"❌ Assertion error during test execution: {ae}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)