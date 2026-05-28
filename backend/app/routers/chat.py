from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from pydantic import BaseModel
from app.database import get_db
from app.models import User
from app.models.education import EducationLevel, Classe
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, RefreshRequest
from app.utils.auth import hash_password, verify_password, create_access_token, create_refresh_token, decode_token, get_current_user
from datetime import datetime, timedelta, timezone
import uuid, random, string
from app.config import settings


class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    email: str
    code: str
    new_password: str


# Stockage en mémoire des codes (suffisant pour démo hackathon)
_reset_codes: dict[str, tuple[str, datetime]] = {}

router = APIRouter(prefix="/auth", tags=["Authentification"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Cet email est déjà utilisé")

    if data.phone:
        result = await db.execute(select(User).where(User.phone == data.phone))
        if result.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Ce numéro de téléphone est déjà utilisé")

    if data.level_id is not None:
        lvl = await db.execute(select(EducationLevel).where(EducationLevel.id == data.level_id))
        if not lvl.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Niveau scolaire invalide")

    if data.classe_id is not None:
        cls = await db.execute(select(Classe).where(Classe.id == data.classe_id))
        if not cls.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Classe invalide")

    user = User(
        id=str(uuid.uuid4()),
        full_name=data.full_name,
        email=data.email,
        password_hash=hash_password(data.password),
        phone=data.phone,
        level_id=data.level_id,
        classe_id=data.classe_id,
        ville=data.ville,
    )
    db.add(user)
    try:
        await db.commit()
        await db.refresh(user)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Données invalides (niveau ou classe introuvable)")

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user_id=user.id,
        full_name=user.full_name,
        is_teacher=user.is_teacher,
    )


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Compte désactivé")

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user_id=user.id,
        full_name=user.full_name,
        is_teacher=user.is_teacher,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(data: RefreshRequest, db: AsyncSession = Depends(get_db)):
    user_id = decode_token(data.refresh_token, expected_type="refresh")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="Token invalide")

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        user_id=user.id,
        full_name=user.full_name,
        is_teacher=user.is_teacher,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: User = Depends(get_current_user)):
    # JWT stateless : le client supprime ses tokens localement.
    # Cette route confirme que le token était valide au moment de la déconnexion.
    return


@router.post("/forgot-password")
async def forgot_password(data: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()
    # Ne pas révéler si l'email existe ou non
    code = ''.join(random.choices(string.digits, k=6))
    if user:
        _reset_codes[data.email] = (code, datetime.now(timezone.utc) + timedelta(minutes=15))
    return {
        "message": "Si cet email est enregistré, un code de réinitialisation vous a été envoyé.",
        "demo_code": code if (user and settings.DEBUG) else None,  # Visible en dev/démo uniquement
    }


@router.post("/reset-password")
async def reset_password(data: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    if len(data.new_password) < 8:
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins 8 caractères")
    entry = _reset_codes.get(data.email)
    if not entry or entry[1] < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Code invalide ou expiré")
    if entry[0] != data.code:
        raise HTTPException(status_code=400, detail="Code incorrect")
    result = await db.execute(select(User).where(User.email == data.email))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    user.password_hash = hash_password(data.new_password)
    await db.commit()
    del _reset_codes[data.email]
    return {"message": "Mot de passe réinitialisé avec succès"}


@router.patch("/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    data: ChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not verify_password(data.old_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Ancien mot de passe incorrect")
    if len(data.new_password) < 8:
        raise HTTPException(status_code=400, detail="Le nouveau mot de passe doit contenir au moins 8 caractères")
    current_user.password_hash = hash_password(data.new_password)
    await db.commit()
    return
